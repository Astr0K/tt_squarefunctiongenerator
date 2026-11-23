import cocotb
from cocotb.triggers import Timer

async def cycle(d, ui, rst=1):
    d.clk.value=0; d.ui_in.value=ui; d.rst_n.value=rst
    await Timer(50,unit='ns')
    d.clk.value=1
    await Timer(50,unit='ns')
    return int(d.uo_out.value)

async def hold(d, ui, n):
    for _ in range(n): out=await cycle(d,ui)
    return out

async def init(d, level=0):
    d.ena.value=1; d.uio_in.value=0
    await cycle(d,0,0)
    await hold(d,level,250)

async def cue(d, ui):
    for _ in range(50000):
        out=await cycle(d,ui)
        if out&128: return
    assert False,'Missing cue'

@cocotb.test()
async def windows_and_results(d):
    for level,width in enumerate([10000,5000,2500,1250]):
        await init(d,level)
        ui=4|level
        await cue(d,ui)
        count=0; out=128
        while out&128:
            count+=1
            out=await cycle(d,ui)
        assert count==width,(level,count,width)
        assert out==0x71
        assert await hold(d,ui,150)==0x71
        await hold(d,ui|16,120)
        await hold(d,ui,120)
        await cue(d,ui)
        assert await hold(d,ui|8,110)==0x3d
        assert await hold(d,ui,150)==0x3d
        assert int(d.uio_oe.value)==0 and int(d.uio_out.value)==0

@cocotb.test()
async def bounce_and_early_response(d):
    await init(d)
    # Each low interval breaks the 100-sample qualification interval.
    for _ in range(5):
        await hold(d,1,40)
        assert await hold(d,0,10)==6
    assert await hold(d,1,110)==0x5b
    for _ in range(5):
        await hold(d,0,40)
        assert await hold(d,1,10)==0x5b
    assert await hold(d,0,110)==6
    ui=4
    await hold(d,ui,150)
    # Response bounce during waiting must not create a false start.
    for _ in range(5):
        assert await hold(d,ui|8,40)==6
        assert await hold(d,ui,10)==6
    # A sustained early press is a real failure.
    assert await hold(d,ui|8,110)==0x71
    await hold(d,ui,110)
    # Restart glitches must not clear the latched result.
    for _ in range(5):
        assert await hold(d,ui|16,40)==0x71
        assert await hold(d,ui,10)==0x71
    assert await hold(d,ui|16,110)==6
    await hold(d,ui,110)
    await cue(d,ui)
    # A bounced response in the window succeeds only once stable.
    for _ in range(5):
        assert await hold(d,ui|8,40)&128
        assert await hold(d,ui,10)&128
    assert await hold(d,ui|8,110)==0x3d
    # Brief disable pulses cannot erase the result.
    for _ in range(5):
        assert await hold(d,0,40)==0x3d
        assert await hold(d,ui,10)==0x3d
    assert await hold(d,0,110)==6

@cocotb.test()
async def reset_release_filter(d):
    await init(d)
    await hold(d,12,250)
    assert int(d.uo_out.value)==0x71
    await cycle(d,12,0)
    for _ in range(4):
        assert await hold(d,12,40)==6
        await cycle(d,12,0)
    assert await hold(d,12,80)==6
    # Stable release eventually accepts controls and records held early press.
    assert await hold(d,12,200)==0x71
