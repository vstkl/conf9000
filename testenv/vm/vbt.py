# Virtual Bluetooth adapter for the test VM: a bumble-emulated controller on /dev/vhci
# plus a second emulated "device" on the same virtual link that advertises, so scans find something.
import asyncio
from bumble.controller import Controller
from bumble.device import Device
from bumble.host import Host
from bumble.link import LocalLink
from bumble.transport import open_transport

async def main():
    async with await open_transport("vhci") as (src, sink):
        link = LocalLink()
        Controller("vbt-adapter", host_source=src, host_sink=sink, link=link)
        peer = Device.with_hci("Test Speaker", "F0:F1:F2:F3:F4:F5",
                               *(lambda c: (c, c))(Controller("vbt-peer", link=link)))
        await peer.power_on()
        await peer.start_advertising(auto_restart=True)
        await asyncio.get_running_loop().create_future()

asyncio.run(main())
