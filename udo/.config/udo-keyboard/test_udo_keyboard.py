"""Tests for udo_keyboard. Run: python3 -m unittest host/test_udo_keyboard.py"""
import logging
import os
import sys
import unittest
from datetime import datetime, timedelta, timezone

sys.path.insert(0, os.path.dirname(__file__))
import udo_keyboard as uk  # noqa: E402

NOW = datetime(2026, 11, 13, 12, 0, 0, tzinfo=timezone.utc)
# Shared with the firmware tests: running, 5025 s, "lab 3" (32 bytes)
SHARED_VECTOR = bytes.fromhex("55010100a11300006c61622033000000") + bytes(16)


def running(task, started):
    return {"task": task, "started": started.isoformat(), "ended": None, "minutes": 0}


class EncodeTest(unittest.TestCase):
    def test_encode_shared_vector(self):
        packet = uk.encode(running("lab 3", NOW - timedelta(seconds=5025)), NOW)
        self.assertEqual(packet, SHARED_VECTOR)

    def test_encode_idle(self):
        self.assertEqual(uk.encode(None, NOW), bytes([0x55, 1, 0, 0]) + bytes(28))

    def test_name_transliterated_and_truncated(self):
        self.assertEqual(uk.ascii_name("Übung Größe 🚀 extra lang"), b"Uebung Groesse  extra la")
        self.assertEqual(len(uk.ascii_name("x" * 40)), 24)

    def test_control_characters_dropped(self):
        self.assertEqual(uk.ascii_name("a\nb\tc\x7fd\x00e"), b"abcde")

    def test_negative_elapsed_clamped(self):
        packet = uk.encode(running("t", NOW + timedelta(minutes=5)), NOW)
        self.assertEqual(packet[4:8], bytes(4))

    def test_started_with_offset_parses(self):
        # udo prints local time with offset, e.g. 2026-11-13T01:36:34.887+01:00
        packet = uk.encode({"task": "t", "started": "2026-11-13T12:59:00.000+01:00"}, NOW)
        self.assertEqual(int.from_bytes(packet[4:8], "little"), 60)


class MalformedStatusTest(unittest.TestCase):
    def test_naive_started_is_local_time(self):
        local_now = NOW.astimezone()
        started = (local_now - timedelta(seconds=90)).replace(tzinfo=None).isoformat()
        packet = uk.packet_for({"task": "t", "started": started}, NOW)
        self.assertEqual(int.from_bytes(packet[4:8], "little"), 90)

    def test_malformed_status_skipped(self):
        for bad in ({"started": NOW.isoformat()}, {"task": "t"},
                    {"task": "t", "started": "not a time"}, "running", 42):
            self.assertIsNone(uk.packet_for(bad, NOW), bad)

    def test_packet_for_valid_matches_encode(self):
        status = running("lab 3", NOW - timedelta(seconds=5025))
        self.assertEqual(uk.packet_for(status, NOW), SHARED_VECTOR)


class FakeDevice:
    def __init__(self, log):
        self.log = log

    def open_path(self, path):
        self.log.append(("open", path))

    def write(self, data):
        self.log.append(("write", bytes(data)))
        if self.log.count(("fail",)) == 0:
            self.log.append(("fail",))
            raise OSError("device gone")
        return len(data)

    def close(self):
        self.log.append(("close",))


class FakeHid:
    def __init__(self):
        self.log = []

    def enumerate(self):
        corne = {"vendor_id": 0x1D50, "product_id": 0x615E, "product_string": "Corne"}
        return [{**corne, "usage_page": 0xFF60, "usage": 0x61, "path": b"dev1"},
                {**corne, "usage_page": 0x0001, "usage": 0x06, "path": b"keyboard"},
                {"vendor_id": 0x3434, "product_id": 0x0121, "product_string": "Other QMK board",
                 "usage_page": 0xFF60, "usage": 0x61, "path": b"other-qmk"}]

    def device(self):
        return FakeDevice(self.log)


class SenderTest(unittest.TestCase):
    def test_send_failure_reopens(self):
        fake = FakeHid()
        sender = uk.Sender(hid_module=fake)
        self.assertFalse(sender.send(SHARED_VECTOR))
        self.assertTrue(sender.send(SHARED_VECTOR))
        self.assertEqual([e for e in fake.log if e[0] == "open"], [("open", b"dev1")] * 2)

    def test_report_is_prefixed_and_padded(self):
        fake = FakeHid()
        sender = uk.Sender(hid_module=fake)
        sender.send(SHARED_VECTOR)
        sender.send(SHARED_VECTOR)
        writes = [e[1] for e in fake.log if e[0] == "write"]
        self.assertEqual(writes[-1], b"\x00" + SHARED_VECTOR)

    def test_no_device_returns_false(self):
        fake = FakeHid()
        fake.enumerate = lambda: []
        self.assertFalse(uk.Sender(hid_module=fake).send(SHARED_VECTOR))


class HealthLogTest(unittest.TestCase):
    def test_logs_only_on_transition(self):
        health = uk.Health("udo")
        with self.assertLogs("udo-status", level="INFO") as logs:
            health.update(False, "udo status failed: boom")
            health.update(False, "udo status failed: boom")
            health.update(False, "udo status failed: boom")
            health.update(True)
            health.update(True)
        self.assertEqual(len(logs.output), 2)
        self.assertIn("boom", logs.output[0])
        self.assertIn("udo ok", logs.output[1])

    def test_first_success_is_silent(self):
        health = uk.Health("udo")
        # assertNoLogs is 3.10+; log a marker so assertLogs has a record
        logger = logging.getLogger("udo-status")
        with self.assertLogs(logger, level="INFO") as logs:
            health.update(True)
            logger.info("marker")
        self.assertEqual(logs.output, ["INFO:udo-status:marker"])


class ChangeTest(unittest.TestCase):
    def test_changed_ignores_elapsed(self):
        a = uk.encode(running("lab 3", NOW - timedelta(seconds=10)), NOW)
        b = uk.encode(running("lab 3", NOW - timedelta(seconds=70)), NOW)
        c = uk.encode(running("lab 4", NOW - timedelta(seconds=70)), NOW)
        self.assertFalse(uk.changed(a, b))
        self.assertTrue(uk.changed(a, c))
        self.assertTrue(uk.changed(None, a))


if __name__ == "__main__":
    unittest.main()
