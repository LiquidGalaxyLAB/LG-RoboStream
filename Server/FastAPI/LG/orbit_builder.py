import time
import threading
import ctypes
from paramiko import SSHClient, AutoAddPolicy


class OrbitBuilder:
    def _init_(self, ip, port=22, user="lg", password="1234asdfASDF"):
        self.ip = ip
        self.port = port
        self.user = user
        self.password = password

        self._stop_event = threading.Event()
        self._thread = None

    def _connect(self):
        client = SSHClient()
        client.set_missing_host_key_policy(AutoAddPolicy())
        client.connect(
            hostname=self.ip,
            port=self.port,
            username=self.user,
            password=self.password,
            timeout=10
        )
        return client

    def _send_query(self, client, content):
        cmd = f"bash -lc 'cat > /tmp/query.txt <<\"EOF\"\n{content}\nEOF'"
        stdin, stdout, stderr = client.exec_command(cmd)
        rc = stdout.channel.recv_exit_status()
        if rc != 0:
            raise RuntimeError(stderr.read().decode() or f"Non-zero exit status {rc}")

    def _build_lookat(self, lat, lon, zoom, tilt, heading):
        return (
            "<gx:duration>0.1</gx:duration>"
            "<gx:flyToMode>smooth</gx:flyToMode>"
            "<LookAt>"
            f"<longitude>{lon}</longitude>"
            f"<latitude>{lat}</latitude>"
            f"<range>{zoom}</range>"
            f"<tilt>{tilt}</tilt>"
            f"<heading>{heading}</heading>"
            "<altitudeMode>relativeToGround</altitudeMode>"
            "</LookAt>"
        )

    def _orbit_loop(self, lat, lon, zoom, tilt, steps, step_ms, start_heading):
        client = None
        try:
            client = self._connect()
            self._send_query(client, "exittour=true")
            time.sleep(0.1)

            delta = 360.0 / max(1, steps)
            heading = start_heading % 360.0

            while not self._stop_event.is_set():
                lookat = self._build_lookat(lat, lon, zoom, tilt, heading)
                try:
                    self._send_query(client, f"flytoview={lookat}")
                except Exception as e:
                    try:
                        if client:
                            client.close()
                    except:
                        pass
                    try:
                        client = self._connect()
                        self._send_query(client, f"flytoview={lookat}")
                    except Exception as e2:
                        print(f"[orbit_loop] send/reconnect error: {e2}")
                        break 

                if self._stop_event.wait(step_ms / 1000.0):
                    break

                heading = (heading + delta) % 360.0

            try:
                self._send_query(client, "exittour=true")
            except Exception:
                pass

        except Exception as e:
            print(f"[orbit_loop] error: {e}")
        finally:
            try:
                if client:
                    client.close()
            except:
                pass
            self._thread = None
            self._stop_event.clear()


    def start_orbit(self, lat, lon, zoom, tilt, steps=30, step_ms=500, start_heading=0.0) -> bool:
        if self._thread and self._thread.is_alive():
            return False

        self._stop_event.clear()
        self._thread = threading.Thread(
            target=self._orbit_loop,
            args=(lat, lon, zoom, tilt, steps, step_ms, start_heading),
            daemon=True
        )
        self._thread.start()
        return True

    def _kill_thread(self, thread):
        if not thread or not thread.is_alive():
            return
        res = ctypes.pythonapi.PyThreadState_SetAsyncExc(
            ctypes.c_long(thread.ident),
            ctypes.py_object(SystemExit)
        )
        if res == 0:
            raise ValueError("Hilo no encontrado")
        elif res > 1:
            ctypes.pythonapi.PyThreadState_SetAsyncExc(thread.ident, 0)
            raise SystemError("Fallo al forzar cierre del hilo")

    def stop_orbit(self, timeout: float = 2.0, force: bool = False) -> bool:
        if not self._thread or not self._thread.is_alive():
            try:
                client = self._connect()
                self._send_query(client, "exittour=true")
                client.close()
            except Exception:
                pass
            return False

        self._stop_event.set()
        self._thread.join(timeout=timeout)

        if self._thread and self._thread.is_alive():
            if force:
                try:
                    self._kill_thread(self._thread)
                except Exception as e:
                    print(f"[stop_orbit/force] error: {e}")
                    return False
            else:
                return False

        try:
            client = self._connect()
            self._send_query(client, "exittour=true")
            client.close()
        except Exception:
            pass

        self._thread = None
        self._stop_event.clear()
        return True

    def is_running(self) -> bool:
        return bool(self._thread and self._thread.is_alive())