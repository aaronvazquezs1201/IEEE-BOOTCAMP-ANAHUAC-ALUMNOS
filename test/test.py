import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


async def submit_code(dut, code):
    dut.ui_in.value = (1 << 4) | (code & 0xF)
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = code & 0xF
    await ClockCycles(dut.clk, 1)


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start 4-bit Hex Digital Safe test with custom PIN")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    assert int(dut.uio_oe.value) == 0xFF
    assert int(dut.uo_out.value) == 0x3F   # '0'
    assert int(dut.uio_out.value) == 0x4F  # '3'

    # 1. Abrir con contraseña inicial (0xA)
    await submit_code(dut, 0xA)
    assert int(dut.uo_out.value) == 0xBE   # 'U.'
    assert int(dut.uio_out.value) == 0x4F  # '3'

    # 2. Activar prog_mode (ui_in[7]=1) y configurar nueva contraseña 0xC
    dut.ui_in.value = (1 << 7) | 0xC
    await ClockCycles(dut.clk, 1)
    assert int(dut.uo_out.value) == 0xB9   # 'C.'
    assert int(dut.uio_out.value) == 0xF3  # 'P.'

    # Guardar con pulso en enter_btn (ui_in[4])
    dut.ui_in.value = (1 << 7) | (1 << 4) | 0xC
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = (1 << 7) | 0xC
    await ClockCycles(dut.clk, 1)

    # Salir de prog_mode y cerrar caja (lock_btn = ui_in[5])
    dut.ui_in.value = 1 << 5
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 1)
    assert int(dut.uo_out.value) == 0x3F   # '0'

    # 3. Probar contraseña vieja (0xA) -> debe fallar (quedan 2 intentos)
    await submit_code(dut, 0xA)
    assert int(dut.uo_out.value) == 0x77   # 'A'
    assert int(dut.uio_out.value) == 0x5B  # '2'

    # 4. Probar nueva contraseña (0xC) -> debe abrir
    await submit_code(dut, 0xC)
    assert int(dut.uo_out.value) == 0xBE   # 'U.'
    assert int(dut.uio_out.value) == 0x4F  # '3'

    # 5. Cerrar y forzar LOCKOUT con 3 fallos
    dut.ui_in.value = 1 << 5
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 1)

    await submit_code(dut, 0x1)
    await submit_code(dut, 0x2)
    await submit_code(dut, 0xF)
    assert int(dut.uo_out.value) == 0x38   # 'L'
    assert int(dut.uio_out.value) == 0xBF  # '0.'

    # 6. Verificar registro de accesos (log_mode = ui_in[6])
    # Entrada 1: 0xA denegado ('A.' y 'd.')
    dut.ui_in.value = (1 << 6) | 1
    await ClockCycles(dut.clk, 1)
    assert int(dut.uo_out.value) == 0xF7
    assert int(dut.uio_out.value) == 0xDE

    # Entrada 2: 0xC aceptado ('C.' y 'A.')
    dut.ui_in.value = (1 << 6) | 2
    await ClockCycles(dut.clk, 1)
    assert int(dut.uo_out.value) == 0xB9
    assert int(dut.uio_out.value) == 0xF7
