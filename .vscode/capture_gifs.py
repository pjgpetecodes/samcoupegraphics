"""Record animated GIFs of the tutorial disks running in SimCoupe.

Usage: python .vscode/capture_gifs.py [disk ...]
Writes assembly/<blog>/gifs/<name>.gif. Needs Pillow, and SimCoupe in .\\simcoupe.
"""
import ctypes
import subprocess
import sys
import time
from ctypes import wintypes
from pathlib import Path

import mss
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
user32 = ctypes.windll.user32
user32.SetProcessDPIAware()

KEYS = {"SPACE": 0x20, "ENTER": 0x0D, "Z": 0x5A, "X": 0x58, "1": 0x31, "2": 0x32, "3": 0x33, "4": 0x34, "5": 0x35}
FULL_SCREEN_DISKS = {"9-1", "10-1", "11-1", "12-1", "12-2", "13-1", "14-1", "15-1", "16-1", "16-2", "17-1", "18-1", "18-2", "19-1", "20-1", "21-1", "21-2", "22-1", "23-1", "24-1", "25-1", "26-1", "27-1", "28-1", "29-1"}

# disk -> (output folder, gif name, script). Script steps: ("wait", s), ("skip", s) unrecorded wait, ("down", key), ("up", key)
IDLE = [("wait", 3.0)]
WALK = [("wait", 1.0), ("down", "Z"), ("wait", 1.8), ("up", "Z"), ("wait", 0.6),
        ("down", "X"), ("wait", 1.8), ("up", "X"), ("wait", 0.6),
        ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"), ("wait", 1.6)]
JOBS = {
    "29-1": ("blog27", "blog27-step1", [
        ("wait", 0.6), ("down", "Z"), ("wait", 1.6), ("up", "Z"),
        ("wait", 0.4), ("down", "ENTER"), ("wait", 1.0), ("up", "ENTER"),
        ("wait", 1.4), ("down", "Z"), ("wait", 7.0), ("up", "Z"),
        ("wait", 0.5), ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"),
        ("wait", 1.0), ("down", "ENTER"), ("wait", 1.0), ("up", "ENTER"),
        ("wait", 1.4), ("down", "SPACE"), ("wait", 0.1),
        ("up", "SPACE"), ("wait", 1.0),
        ("down", "Z"), ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"),
        ("wait", 2.4), ("up", "Z"), ("wait", 1.0),
        ("down", "Z"), ("wait", 2.5), ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"),
        ("wait", 3.4), ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"), ("wait", 0.2), ("up", "Z"),
        ("wait", 0.6), ("down", "ENTER"), ("wait", 1.0), ("up", "ENTER"),
        ("wait", 3.0),
    ]),
    "28-1": ("blog26", "blog26-step1", [
        ("skip", 0.6), ("down", "Z"), ("skip", 1.6), ("up", "Z"),
        ("skip", 0.4), ("down", "ENTER"), ("skip", 1.0), ("up", "ENTER"),
        ("skip", 1.4), ("down", "Z"), ("skip", 7.0), ("up", "Z"),
        ("skip", 0.5), ("down", "SPACE"), ("skip", 0.1), ("up", "SPACE"),
        ("skip", 1.0), ("down", "ENTER"), ("skip", 1.0), ("up", "ENTER"),
        ("skip", 1.4), ("down", "SPACE"), ("skip", 0.1),
        ("up", "SPACE"), ("skip", 1.0),
        ("down", "Z"), ("down", "SPACE"), ("skip", 0.1), ("up", "SPACE"),
        ("skip", 2.4), ("up", "Z"), ("skip", 1.0),
        ("down", "Z"), ("skip", 2.5), ("down", "SPACE"), ("skip", 0.1), ("up", "SPACE"),
        ("skip", 3.4), ("down", "SPACE"), ("skip", 0.1), ("up", "SPACE"), ("skip", 0.2), ("up", "Z"),
        ("wait", 1.0),
        ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"), ("wait", 1.0),
        ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"), ("wait", 1.0),
        ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"), ("wait", 1.0),
        ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"), ("wait", 1.0),
        ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"), ("wait", 1.0),
        ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"), ("wait", 1.0),
        ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"), ("wait", 1.0),
        ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"), ("wait", 1.0),
        ("wait", 3.0),
    ]),
    "27-1": ("blog25", "blog25-step1", [
        ("skip", 0.6), ("down", "Z"), ("skip", 1.6), ("up", "Z"),
        ("skip", 0.4), ("down", "ENTER"), ("skip", 1.0), ("up", "ENTER"),
        ("skip", 1.4), ("down", "Z"), ("skip", 7.0), ("up", "Z"),
        ("skip", 0.5), ("down", "SPACE"), ("skip", 0.1), ("up", "SPACE"),
        ("skip", 1.0), ("down", "ENTER"), ("skip", 1.0), ("up", "ENTER"),
        ("skip", 1.4), ("down", "SPACE"), ("skip", 0.1),
        ("up", "SPACE"), ("skip", 1.0),
        ("down", "Z"), ("down", "SPACE"), ("skip", 0.1), ("up", "SPACE"),
        ("skip", 2.4), ("up", "Z"), ("skip", 1.0),
        ("down", "Z"), ("skip", 2.0), ("wait", 2.0), ("up", "Z"),
        ("wait", 7.0),
    ]),
    "26-1": ("blog24", "blog24-step1", [
        ("wait", 0.6), ("down", "Z"), ("wait", 1.6), ("up", "Z"),
        ("wait", 0.4), ("down", "ENTER"), ("wait", 1.0), ("up", "ENTER"),
        ("wait", 0.8), ("down", "X"), ("wait", 4.0), ("up", "X"),
        ("wait", 4.0),
    ]),
    "25-1": ("blog23", "blog23-step1", [
        ("wait", 1.0), ("down", "X"), ("wait", 1.0), ("up", "X"),
        ("wait", 1.0), ("down", "X"), ("wait", 0.8), ("up", "X"),
        ("wait", 2.0), ("down", "Z"), ("wait", 1.4), ("up", "Z"),
        ("wait", 1.5),
    ]),
    "24-1": ("blog22", "blog22-step1", [
        ("wait", 2.0), ("down", "X"), ("wait", 1.5), ("up", "X"),
        ("wait", 3.0), ("down", "Z"), ("wait", 1.0), ("up", "Z"),
        ("wait", 1.5),
    ]),
    "23-1": ("blog21", "blog21-step1", [
        ("wait", 0.6), ("down", "Z"), ("wait", 1.1), ("up", "Z"),
        ("wait", 0.4), ("down", "ENTER"), ("wait", 1.0), ("up", "ENTER"),
        ("wait", 1.4), ("down", "Z"), ("wait", 7.0), ("up", "Z"),
        ("wait", 0.5), ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"),
        ("wait", 1.0), ("down", "ENTER"), ("wait", 1.0), ("up", "ENTER"),
        ("wait", 1.4), ("down", "SPACE"), ("wait", 0.1),
        ("up", "SPACE"), ("wait", 1.0),
        ("down", "Z"), ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"),
        ("wait", 2.4), ("up", "Z"), ("wait", 1.0),
        ("down", "Z"), ("wait", 1.3), ("up", "Z"), ("wait", 1.0),
        ("down", "X"), ("wait", 1.3), ("up", "X"), ("wait", 1.0),
        ("down", "Z"), ("wait", 4.0), ("up", "Z"), ("wait", 0.5),
        ("down", "X"), ("wait", 5.0), ("up", "X"), ("wait", 1.0),
    ]),
    "22-1": ("blog20", "blog20-step1", [
        ("wait", 0.6), ("down", "Z"), ("wait", 1.1), ("up", "Z"),
        ("wait", 0.4), ("down", "ENTER"), ("wait", 1.0), ("up", "ENTER"),
        ("wait", 1.4), ("down", "Z"), ("wait", 7.0), ("up", "Z"),
        ("wait", 0.5), ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"),
        ("wait", 1.0), ("down", "ENTER"), ("wait", 1.0), ("up", "ENTER"),
        ("wait", 1.4), ("down", "SPACE"), ("wait", 0.1),
        ("up", "SPACE"), ("wait", 1.0),
        ("down", "Z"), ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"),
        ("wait", 2.4), ("up", "Z"), ("wait", 1.0),
    ]),
    "21-2": ("blog19", "blog19-step2", [
        ("wait", 0.6), ("down", "ENTER"), ("wait", 1.0), ("up", "ENTER"),
        ("wait", 0.5), ("down", "X"), ("wait", 0.8), ("up", "X"),
        ("wait", 1.2), ("down", "ENTER"), ("wait", 1.0), ("up", "ENTER"),
        ("wait", 1.4),
    ]),
    "21-1": ("blog19", "blog19-step1", [
        ("wait", 0.6), ("down", "ENTER"), ("wait", 1.0), ("up", "ENTER"),
        ("wait", 0.6), ("down", "Z"), ("wait", 0.6), ("up", "Z"),
        ("wait", 0.4), ("down", "ENTER"), ("wait", 1.0), ("up", "ENTER"),
        ("wait", 0.6), ("down", "Z"), ("wait", 0.5), ("up", "Z"),
        ("wait", 0.4), ("down", "ENTER"), ("wait", 1.0), ("up", "ENTER"),
        ("wait", 0.6), ("down", "X"), ("wait", 1.65), ("up", "X"),
        ("wait", 0.4), ("down", "ENTER"), ("wait", 0.4), ("up", "ENTER"),
        ("wait", 0.4), ("down", "Z"), ("wait", 0.6), ("up", "Z"),
        ("wait", 0.4), ("down", "ENTER"), ("wait", 1.0), ("up", "ENTER"),
        ("wait", 0.6), ("down", "Z"), ("wait", 0.6), ("up", "Z"),
        ("wait", 0.4), ("down", "ENTER"), ("wait", 1.0), ("up", "ENTER"),
        ("wait", 0.6), ("down", "Z"), ("wait", 0.6), ("up", "Z"),
        ("wait", 0.4), ("down", "ENTER"), ("wait", 1.0), ("up", "ENTER"),
        ("wait", 0.6), ("down", "X"), ("wait", 2.3), ("up", "X"),
        ("wait", 0.4), ("down", "ENTER"), ("wait", 0.4), ("up", "ENTER"),
        ("wait", 0.7),
    ]),
    "20-1": ("blog18", "blog18-step1", [
        ("wait", 0.5), ("down", "ENTER"), ("wait", 0.2), ("up", "ENTER"),
        ("down", "Z"), ("wait", 1.1), ("up", "Z"), ("wait", 0.4),
        ("down", "ENTER"), ("wait", 0.8), ("up", "ENTER"), ("wait", 0.4),
        ("down", "Z"), ("wait", 3.0), ("up", "Z"), ("wait", 0.4),
        ("down", "X"), ("wait", 5.0), ("up", "X"), ("wait", 0.5),
    ]),
    "19-1": ("blog17", "blog17-step1", [
        ("wait", 0.5), ("down", "Z"), ("wait", 11.0), ("up", "Z"),
        ("wait", 0.5), ("down", "X"), ("wait", 8.0), ("up", "X"),
        ("wait", 0.5), ("down", "Z"), ("wait", 6.0), ("up", "Z"),
        ("wait", 0.5),
    ]),
    "18-1": ("blog16", "blog16-step1", [
        ("wait", 0.5), ("down", "SPACE"), ("wait", 2.0), ("up", "SPACE"),
        ("wait", 0.3), ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"),
        ("wait", 0.08), ("down", "SPACE"), ("wait", 1.0), ("up", "SPACE"),
        ("wait", 0.3), ("down", "X"), ("down", "SPACE"), ("wait", 0.1),
        ("up", "SPACE"), ("wait", 1.0), ("up", "X"), ("wait", 0.5),
    ]),
    "18-2": ("blog16", "blog16-step2", [
        ("wait", 0.5), ("down", "SPACE"), ("wait", 1.5), ("up", "SPACE"),
        ("wait", 0.4), ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"),
        ("wait", 0.8),
    ]),
    "17-1": ("blog15", "blog15-step1", [
        ("wait", 0.6), ("down", "X"), ("wait", 2.7), ("up", "X"),
        ("wait", 0.7), ("down", "Z"), ("wait", 2.7), ("up", "Z"),
        ("wait", 0.6),
    ]),
    "16-2": ("blog14", "blog14-step2", [
        ("wait", 0.5), ("down", "X"), ("wait", 2.5), ("up", "X"),
        ("wait", 0.7), ("down", "Z"), ("wait", 2.5), ("up", "Z"),
        ("wait", 0.5),
    ]),
    "16-1": ("blog14", "blog14-step1", [
        ("wait", 0.5), ("down", "Z"), ("wait", 3.0), ("up", "Z"),
        ("wait", 0.5), ("down", "X"), ("wait", 4.0), ("up", "X"),
        ("wait", 0.5), ("down", "Z"), ("wait", 3.0), ("up", "Z"),
        ("wait", 0.5),
    ]),
    "15-1": ("blog13", "blog13-step1", [
        ("wait", 0.4), ("down", "Z"), ("wait", 3.0), ("up", "Z"),
        ("wait", 0.4), ("down", "X"), ("wait", 4.0), ("up", "X"),
        ("wait", 0.4), ("down", "Z"), ("wait", 4.0), ("up", "Z"),
        ("wait", 0.4), ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"),
        ("wait", 1.0),
    ]),
    "14-1": ("blog12", "blog12-step1", [
        ("wait", 0.5), ("down", "X"), ("wait", 4.0), ("up", "X"),
        ("wait", 0.3), ("down", "Z"), ("wait", 4.0), ("up", "Z"),
        ("wait", 0.5),
    ]),
    "13-1": ("blog11", "blog11-step1", [
        ("wait", 0.4), ("down", "X"), ("wait", 4.0), ("up", "X"),
        ("wait", 0.3), ("down", "Z"), ("wait", 4.0), ("up", "Z"),
        ("wait", 0.3), ("down", "X"), ("wait", 1.0), ("up", "X"),
        ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"), ("wait", 1.3),
        ("down", "Z"), ("down", "X"), ("wait", 0.3),
        ("up", "Z"), ("up", "X"), ("wait", 0.4),
    ]),
    "12-1": ("blog10", "blog10-step1", [("wait", 2.0)]),
    "12-2": ("blog10", "blog10-step2", [("wait", 2.0)]),
    "11-1": ("blog9", "blog9-step1", [
        ("wait", 0.4), ("down", "X"), ("wait", 0.12), ("up", "X"),
        ("wait", 0.2), ("down", "X"), ("wait", 6.0), ("up", "X"),
        ("wait", 0.5), ("down", "Z"), ("wait", 6.0), ("up", "Z"),
        ("wait", 0.5), ("down", "X"), ("down", "SPACE"), ("wait", 0.1),
        ("up", "SPACE"), ("wait", 0.2), ("up", "X"), ("wait", 0.8),
        ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"), ("wait", 1.2),
        ("down", "Z"), ("down", "X"), ("wait", 0.3),
        ("up", "Z"), ("up", "X"), ("wait", 0.5),
    ]),
    "10-1": ("blog8", "blog8-step1", [
        ("wait", 0.4), ("down", "X"), ("wait", 2.6), ("up", "X"),
        ("wait", 0.3), ("down", "Z"), ("wait", 2.6), ("up", "Z"),
        ("wait", 0.3), ("down", "X"), ("wait", 0.6),
        ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"),
        ("wait", 0.2), ("up", "X"), ("wait", 0.8),
        ("down", "Z"), ("down", "X"), ("wait", 0.3),
        ("up", "Z"), ("up", "X"), ("wait", 0.3),
    ]),
    "9-1": ("blog7", "blog7-step1", [
        ("wait", 0.6), ("down", "Z"), ("wait", 1.2), ("up", "Z"),
        ("wait", 0.4), ("down", "X"), ("wait", 1.2), ("up", "X"),
        ("down", "Z"), ("down", "SPACE"), ("wait", 0.1),
        ("up", "SPACE"), ("up", "Z"), ("wait", 1.1),
        ("down", "X"), ("down", "SPACE"), ("wait", 0.1),
        ("up", "SPACE"), ("up", "X"), ("wait", 1.1),
        ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"),
        ("wait", 1.2), ("down", "2"), ("wait", 0.1), ("up", "2"),
        ("wait", 0.5), ("down", "1"), ("wait", 0.1), ("up", "1"),
        ("wait", 0.5),
    ]),
    "6-1": ("blog4", "blog4-step1", [("wait", 4.0)]),
    "6-2": ("blog4", "blog4-step2", IDLE),
    "6-3": ("blog4", "blog4-step3", [("wait", 4.0)]),
    "6-4": ("blog4", "blog4-step4", [("wait", 4.0)]),
    "7-1": ("blog5", "blog5-step1", [("wait", 0.8), ("down", "X"), ("wait", 0.1), ("up", "X"), ("wait", 1.8)]),
    "7-2": ("blog5", "blog5-step2", [("wait", 0.8), ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"), ("wait", 1.8)]),
    "7-3": ("blog5", "blog5-step3", WALK),
    "8-1": ("blog6", "blog6-step1", WALK),
    "8-2": ("blog6", "blog6-step2", [("wait", 0.6)] + sum(
        ([("down", k), ("wait", 0.15), ("up", k), ("wait", 0.7)] for k in "12345"), [])
        + [("down", "Z"), ("wait", 1.2), ("up", "Z"), ("wait", 0.3)]),
    "8-3": ("blog6", "blog6-step3", [("wait", 0.8), ("down", "Z"), ("wait", 0.3), ("down", "SPACE"), ("wait", 0.1),
                                      ("up", "SPACE"), ("up", "Z"), ("wait", 1.8),
                                      ("down", "X"), ("wait", 0.3), ("down", "SPACE"), ("wait", 0.1),
                                      ("up", "SPACE"), ("up", "X"), ("wait", 1.8),
                                      ("down", "SPACE"), ("wait", 0.1), ("up", "SPACE"), ("wait", 1.6)]),
}


def window_rect(hwnd):
    r = wintypes.RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(r))
    return r.left, r.top, r.right, r.bottom


def find_window(pid):
    found = []

    @ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
    def cb(hwnd, _):
        p = wintypes.DWORD()
        user32.GetWindowThreadProcessId(hwnd, ctypes.byref(p))
        if p.value == pid and user32.IsWindowVisible(hwnd) and user32.GetWindowTextLengthW(hwnd):
            found.append(hwnd)
        return True

    user32.EnumWindows(cb, 0)
    return found[0] if found else None


def record(disk):
    folder, name, script = JOBS[disk]
    command = [str(ROOT / "simcoupe" / "SimCoupe.exe"), str(ROOT / "disks" / f"{disk}.dsk")]
    if disk in FULL_SCREEN_DISKS:
        command.extend(["-mainmemory", "256", "-scale", "2", "-fullscreen", "0"])
    proc = subprocess.Popen(command)
    held = set()
    sct = None
    try:
        time.sleep(6)
        hwnd = find_window(proc.pid)
        if hwnd is None:
            raise RuntimeError(f"No SimCoupe window found for process {proc.pid}")
        foreground = user32.GetForegroundWindow()
        foreground_thread = user32.GetWindowThreadProcessId(foreground, None)
        thread = ctypes.windll.kernel32.GetCurrentThreadId()
        attached = user32.AttachThreadInput(thread, foreground_thread, True)
        try:
            user32.ShowWindow(hwnd, 9)
            user32.SetForegroundWindow(hwnd)
        finally:
            if attached:
                user32.AttachThreadInput(thread, foreground_thread, False)
        time.sleep(0.5)
        if user32.GetForegroundWindow() != hwnd:
            raise RuntimeError("SimCoupe is not foreground; refusing to inject keys")
        left, top, right, bottom = window_rect(hwnd)
        # Dizzy sits near the top left of the emulated screen; crop around him
        crop = {"left": left + 400, "top": top + 340, "width": 420, "height": 280}
        if disk in FULL_SCREEN_DISKS:
            client = wintypes.RECT()
            user32.GetClientRect(hwnd, ctypes.byref(client))
            origin = wintypes.POINT(0, 0)
            user32.ClientToScreen(hwnd, ctypes.byref(origin))
            crop = {"left": origin.x, "top": origin.y,
                    "width": client.right, "height": client.bottom}
        sct = mss.MSS()
        frames, stamps = [], []
        start = time.time()

        def grab():
            if user32.GetForegroundWindow() != hwnd:
                raise RuntimeError("SimCoupe lost focus during capture")
            shot = sct.grab(crop)
            image = Image.frombytes("RGB", shot.size, shot.bgra, "raw", "BGRX")
            if disk in FULL_SCREEN_DISKS:
                image = image.resize((640, 480), Image.Resampling.NEAREST)
            frames.append(image)
            stamps.append(time.time() - start)

        for kind, arg in script:
            if kind == "wait":
                end = time.time() + arg
                while time.time() < end:
                    grab()
                    time.sleep(0.04)
            elif kind == "skip":
                # Let the game run without recording, e.g. while replaying a route to a later room
                end = time.time() + arg
                while time.time() < end:
                    if user32.GetForegroundWindow() != hwnd:
                        raise RuntimeError("SimCoupe lost focus during capture")
                    time.sleep(0.04)
            elif kind == "down":
                if user32.GetForegroundWindow() != hwnd:
                    raise RuntimeError("SimCoupe lost focus; refusing to inject keys")
                held.add(arg)
                user32.keybd_event(KEYS[arg], 0, 0, 0)
            else:
                user32.keybd_event(KEYS[arg], 0, 2, 0)
                held.discard(arg)
    finally:
        for key in held:
            user32.keybd_event(KEYS[key], 0, 2, 0)
        if sct is not None:
            sct.close()
        proc.kill()
        proc.wait()
    size = (640, 480) if disk in FULL_SCREEN_DISKS else (420, 280)
    small = [f.resize(size, Image.NEAREST) for f in frames]
    sample = Image.new("RGB", (size[0], size[1] * len(small[::5])))
    for i, f in enumerate(small[::5]):
        sample.paste(f, (0, i * size[1]))
    pal = sample.quantize(colors=64)
    quant = [f.quantize(palette=pal, dither=Image.Dither.NONE) for f in small]
    durations = [int((stamps[i + 1] - stamps[i]) * 1000) for i in range(len(stamps) - 1)] + [60]
    out = ROOT / "assembly" / folder / "gifs"
    out.mkdir(exist_ok=True)
    path = out / f"{name}.gif"
    quant[0].save(path, save_all=True, append_images=quant[1:], duration=durations, loop=0, optimize=False)
    print(f"{path}  {len(frames)} frames, {path.stat().st_size // 1024} KB")


if __name__ == "__main__":
    for d in (sys.argv[1:] or JOBS):
        record(d)
