"""Send `udo status` to the Corne's right nice!view.

Polls `udo status --json` every 10 s and sends a 32-byte packet as a raw HID
report to the left (central) half, which relays it to the right half. Sends
right away when the task starts, stops or changes, otherwise every 60 s as a
heartbeat (the right half shows "udo ?" after 180 s without one).

    PY=~/.local/share/udo-keyboard/.venv/bin/python    (created by install.sh)
    $PY ~/.config/udo-keyboard/udo_keyboard.py            run forever
    $PY ~/.config/udo-keyboard/udo_keyboard.py --dry-run  print packets, don't send
    $PY ~/.config/udo-keyboard/udo_keyboard.py --verbose  send and log every packet
    python3 -m unittest ~/.config/udo-keyboard/test_udo_keyboard.py

Packet (32 bytes, little-endian): [0]=0x55 magic, [1]=0x01 version, [2] state
(0 idle, 1 running), [3]=0, [4..7] elapsed seconds (uint32), [8..31] task name,
ASCII, NUL-padded. Must match the firmware's packet.h (corne-zmk repo,
modules/udo-status/include/udo_status/packet.h).
"""

import os
import shutil
import json
import logging
import subprocess
import sys
import time
import unicodedata
from datetime import datetime, timezone

# launchd's PATH (the plist) has no ~/.cargo/bin: added at the end, so a
# brew udo (/opt/homebrew/bin) wins once installed, cargo's is the fallback
UDO_PATH = os.pathsep.join(
    [os.environ.get("PATH", ""), os.path.expanduser("~/.cargo/bin")]
)

MAGIC, VERSION = 0x55, 0x01
PACKET_LEN, NAME_LEN, REPORT_SIZE = 32, 24, 32
USAGE_PAGE, USAGE = 0xFF60, 0x61
PRODUCT = "Corne"  # CONFIG_ZMK_KEYBOARD_NAME; other QMK/VIA boards share the usage
POLL_S, HEARTBEAT_S = 10, 60
UDO = "udo"

log = logging.getLogger("udo-status")

_TRANSLIT = str.maketrans(
    {"ä": "ae", "ö": "oe", "ü": "ue", "Ä": "Ae", "Ö": "Oe", "Ü": "Ue", "ß": "ss"}
)


def ascii_name(task: str) -> bytes:
    """Task name as at most 24 ASCII bytes (the display font is ASCII only)."""
    text = unicodedata.normalize("NFKD", task.translate(_TRANSLIT))
    printable = bytes(b for b in text.encode("ascii", "ignore") if 0x20 <= b <= 0x7E)
    return printable[:NAME_LEN]


def encode(status: dict | None, now: datetime) -> bytes:
    """32-byte packet for the `running` object of `udo status --json` (None = idle)."""
    if status is None:
        return bytes([MAGIC, VERSION, 0, 0]) + bytes(PACKET_LEN - 4)
    started = datetime.fromisoformat(status["started"])
    if started.tzinfo is None:
        started = started.astimezone()  # no offset: local time
    elapsed = min(max(int((now - started).total_seconds()), 0), 2**32 - 1)
    name = ascii_name(status["task"])
    return (
        bytes([MAGIC, VERSION, 1, 0])
        + elapsed.to_bytes(4, "little")
        + name
        + bytes(NAME_LEN - len(name))
    )


def packet_for(status, now: datetime) -> bytes | None:
    """encode(), or None if udo printed a shape we don't understand."""
    try:
        return encode(status, now)
    except (KeyError, ValueError, TypeError, AttributeError):
        return None


class Health:
    """Logs a failure once when it starts and once when it is over."""

    def __init__(self, name: str):
        self.name = name
        self.ok = None

    def update(self, ok: bool, message: str = "") -> None:
        if not ok and self.ok is not False:
            log.warning("%s", message)
        elif ok and self.ok is False:
            log.info("%s ok again", self.name)
        self.ok = ok


def changed(last: bytes | None, packet: bytes) -> bool:
    """True if state or name differ (elapsed time alone is not a change)."""
    return last is None or last[:4] != packet[:4] or last[8:] != packet[8:]


class Sender:
    """Writes packets to every raw HID interface of the keyboard (BLE and USB).

    Devices are opened lazily; any write error closes them all and the next
    send re-enumerates, so sleep/disconnect of the keyboard is survived.
    """

    def __init__(self, hid_module=None):
        if hid_module is None:
            import hid as hid_module
        self.hid = hid_module
        self.devices = []

    def _open(self):
        for info in self.hid.enumerate():
            if (
                info["usage_page"] == USAGE_PAGE
                and info["usage"] == USAGE
                and info.get("product_string") == PRODUCT
            ):
                dev = self.hid.device()
                dev.open_path(info["path"])
                self.devices.append(dev)

    def close(self):
        for dev in self.devices:
            try:
                dev.close()
            except OSError:
                pass
        self.devices = []

    def send(self, packet: bytes) -> bool:
        # Leading 0x00 = "no report ID"; macOS needs it over BLE (see probe.py).
        report = b"\x00" + packet + bytes(REPORT_SIZE - len(packet))
        try:
            if not self.devices:
                self._open()
            if not self.devices:
                return False
            for dev in self.devices:
                if dev.write(report) < 0:
                    raise OSError("write failed")
            return True
        except OSError as err:
            log.debug("send failed: %s", err)
            self.close()
            return False


def read_status() -> tuple[bool, dict | None, str]:
    """(ok, running, error) from `udo status --json`; ok=False if udo failed."""
    udo = shutil.which("udo", path=UDO_PATH)
    if udo is None:
        return False, None, f"udo status failed: no udo on {UDO_PATH}"
    try:
        out = subprocess.run(
            [udo, "status", "--json"],
            capture_output=True,
            timeout=5,
            check=True,
            text=True,
        ).stdout
        return True, json.loads(out)["running"], ""
    except (
        OSError,
        subprocess.SubprocessError,
        ValueError,
        KeyError,
        TypeError,
    ) as err:
        return False, None, f"udo status failed: {err}"


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    dry_run = "--dry-run" in sys.argv
    verbose = "--verbose" in sys.argv
    sender = None if dry_run else Sender()
    last, last_sent_at, connected = None, 0.0, None
    udo = Health("udo")
    while True:
        ok, running, error = read_status()
        packet = packet_for(running, datetime.now(timezone.utc)) if ok else None
        if ok and packet is None:
            error = f"unexpected udo status: {running!r}"
        udo.update(packet is not None, error)
        if packet is not None:
            if changed(last, packet) or time.monotonic() - last_sent_at >= HEARTBEAT_S:
                if dry_run:
                    log.info("packet %s", packet.hex(" "))
                    sent = True
                else:
                    sent = sender.send(packet)
                    if verbose:
                        log.info("%s %s", "sent" if sent else "failed", packet.hex(" "))
                    if sent != connected:
                        log.info(
                            "keyboard %s",
                            "connected" if sent else "not reachable, retrying",
                        )
                        connected = sent
                if sent:
                    last, last_sent_at = packet, time.monotonic()
        time.sleep(POLL_S)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
