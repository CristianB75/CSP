# coding: utf-8
"""*****************************************************************************
* Copyright (C) 2018 Microchip Technology Inc. and its subsidiaries.
*
* Subject to your compliance with these terms, you may use Microchip software
* and any derivatives exclusively with Microchip products. It is your
* responsibility to comply with third party license terms applicable to your
* use of third party software (including open source software) that may
* accompany Microchip software.
*
* THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS". NO WARRANTIES, WHETHER
* EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED
* WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A
* PARTICULAR PURPOSE.
*
* IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,
* INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND
* WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS
* BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE. TO THE
* FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S TOTAL LIABILITY ON ALL CLAIMS IN
* ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF ANY,
* THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
*****************************************************************************"""

################################################################################
#### Global Variables ####
################################################################################

global uartInstanceName
global interruptVector
global interruptHandler
global interruptHandlerLock

################################################################################
#### Business Logic ####
################################################################################

def handleMessage(messageID, args):
    global uartSym_RingBuffer_Enable
    global uartInterrupt
    result_dict = {}

    if (messageID == "UART_RING_BUFFER_MODE"):
        if args.get("isReadOnly") != None:
            uartSym_RingBuffer_Enable.setReadOnly(args["isReadOnly"])
        if args.get("isEnabled") != None:
            uartSym_RingBuffer_Enable.setValue(args["isEnabled"])
        if args.get("isVisible") != None:
            uartSym_RingBuffer_Enable.setVisible(args["isVisible"])
    elif (messageID == "UART_INTERRUPT_MODE"):
        if args.get("isReadOnly") != None:
            uartInterrupt.setReadOnly(args["isReadOnly"])
        if args.get("isEnabled") != None:
            uartInterrupt.setValue(args["isEnabled"])
        if args.get("isVisible") != None:
            uartInterrupt.setVisible(args["isVisible"])

    return result_dict

def interruptControl(uartNVIC, event):

    global interruptVector
    global interruptHandler
    global interruptHandlerLock

    Database.clearSymbolValue("core", interruptVector)
    Database.clearSymbolValue("core", interruptHandler)
    Database.clearSymbolValue("core", interruptHandlerLock)

    if (event["value"] == True):
        Database.setSymbolValue("core", interruptVector, True, 2)
        Database.setSymbolValue("core", interruptHandler, uartInstanceName.getValue() + "_InterruptHandler", 2)
        Database.setSymbolValue("core", interruptHandlerLock, True, 2)
    else :
        Database.setSymbolValue("core", interruptVector, False, 2)
        Database.setSymbolValue("core", interruptHandler, uartInstanceName.getValue() + "_Handler", 2)
        Database.setSymbolValue("core", interruptHandlerLock, False, 2)

def dependencyStatus(symbol, event):

    if (Database.getSymbolValue(uartInstanceName.getValue().lower(), "USART_INTERRUPT_MODE") == True):
        symbol.setVisible(event["value"])

# Calculates BRG value
def baudRateCalc(clk, baud):

    if (clk >= (16 * baud)):
        brgVal = (clk / (16 * baud))
    else :
        brgVal = (clk / (8 * baud))

    return brgVal

def baudRateTrigger(symbol, event):

    clk = Database.getSymbolValue("core", uartInstanceName.getValue() + "_CLOCK_FREQUENCY")
    baud = Database.getSymbolValue(uartInstanceName.getValue().lower(), "BAUD_RATE")

    brgVal = baudRateCalc(clk, baud)
    uartClockInvalidSym.setVisible((brgVal < 1) or (brgVal > 65535))
    symbol.setValue(brgVal, 2)

def clockSourceFreq(symbol, event):

    symbol.clearValue()
    symbol.setValue(int(Database.getSymbolValue("core", uartInstanceName.getValue() + "_CLOCK_FREQUENCY")), 2)

# Dependency Function for symbol visibility
def updateUARTDMAConfigurationVisbleProperty(symbol, event):

    symbol.setVisible(event["value"])

def updateSymbolVisibility(symbol, event):
    global uartInterrupt
    global uartSym_RingBuffer_Enable

    # Enable RX ring buffer size option if Ring buffer is enabled.
    if symbol.getID() == "UART_RX_RING_BUFFER_SIZE":
        symbol.setVisible(uartSym_RingBuffer_Enable.getValue())
    # Enable TX ring buffer size option if Ring buffer is enabled.
    elif symbol.getID() == "UART_TX_RING_BUFFER_SIZE":
        symbol.setVisible(uartSym_RingBuffer_Enable.getValue())
    # If Interrupt is enabled, make ring buffer option visible
    # Further, if Interrupt is disabled, disable the ring buffer mode
    elif symbol.getID() == "UART_RING_BUFFER_ENABLE":
        symbol.setVisible(uartInterrupt.getValue())
        if (uartInterrupt.getValue() == False):
            readOnlyState = symbol.getReadOnly()
            symbol.setReadOnly(True)
            symbol.setValue(False)
            symbol.setReadOnly(readOnlyState)

def UARTFileGeneration(symbol, event):
    componentID = symbol.getID()
    filepath = ""
    ringBufferModeEnabled = event["value"]

    if componentID == "UART_HEADER1":
        if ringBufferModeEnabled == True:
            filepath = "../peripheral/uart_6418/templates/plib_uart_ring_buffer.h.ftl"
        else:
            filepath = "../peripheral/uart_6418/templates/plib_uart.h.ftl"
    elif componentID == "UART_SOURCE1":
        if ringBufferModeEnabled == True:
            filepath = "../peripheral/uart_6418/templates/plib_uart_ring_buffer.c.ftl"
        else:
            filepath = "../peripheral/uart_6418/templates/plib_uart.c.ftl"

    symbol.setSourcePath(filepath)

def onCapabilityConnected(event):
    localComponent = event["localComponent"]
    remoteComponent = event["remoteComponent"]

    # This message should indicate to the dependent component that PLIB has finished its initialization and
    # is ready to accept configuration parameters from the dependent component
    argDict = {"localComponentID" : localComponent.getID()}
    argDict = Database.sendMessage(remoteComponent.getID(), "REQUEST_CONFIG_PARAMS", argDict)
################################################################################
#### Component ####
################################################################################

def instantiateComponent(uartComponent):

    global interruptVector
    global interruptHandler
    global interruptHandlerLock
    global uartInstanceName
    global uartClockInvalidSym
    global uartSym_RingBuffer_Enable
    global uartInterrupt

    uartInstanceName = uartComponent.createStringSymbol("UART_INSTANCE_NAME", None)
    uartInstanceName.setVisible(False)
    uartInstanceName.setDefaultValue(uartComponent.getID().upper())

    uartInterrupt = uartComponent.createBooleanSymbol("USART_INTERRUPT_MODE", None)
    uartInterrupt.setLabel("Interrupt Mode")
    uartInterrupt.setDefaultValue(True)

    #Enable Ring buffer?
    uartSym_RingBuffer_Enable = uartComponent.createBooleanSymbol("UART_RING_BUFFER_ENABLE", None)
    uartSym_RingBuffer_Enable.setLabel("Enable Ring Buffer ?")
    uartSym_RingBuffer_Enable.setDefaultValue(False)
    uartSym_RingBuffer_Enable.setVisible(Database.getSymbolValue(uartInstanceName.getValue().lower(), "USART_INTERRUPT_MODE"))
    uartSym_RingBuffer_Enable.setDependencies(updateSymbolVisibility, ["USART_INTERRUPT_MODE"])

    uartSym_TXRingBuffer_Size = uartComponent.createIntegerSymbol("UART_TX_RING_BUFFER_SIZE", uartSym_RingBuffer_Enable)
    uartSym_TXRingBuffer_Size.setLabel("TX Ring Buffer Size")
    uartSym_TXRingBuffer_Size.setMin(2)
    uartSym_TXRingBuffer_Size.setMax(65535)
    uartSym_TXRingBuffer_Size.setDefaultValue(128)
    uartSym_TXRingBuffer_Size.setVisible(False)
    uartSym_TXRingBuffer_Size.setDependencies(updateSymbolVisibility, ["UART_RING_BUFFER_ENABLE"])

    uartSym_RXRingBuffer_Size = uartComponent.createIntegerSymbol("UART_RX_RING_BUFFER_SIZE", uartSym_RingBuffer_Enable)
    uartSym_RXRingBuffer_Size.setLabel("RX Ring Buffer Size")
    uartSym_RXRingBuffer_Size.setMin(2)
    uartSym_RXRingBuffer_Size.setMax(65535)
    uartSym_RXRingBuffer_Size.setDefaultValue(128)
    uartSym_RXRingBuffer_Size.setVisible(False)
    uartSym_RXRingBuffer_Size.setDependencies(updateSymbolVisibility, ["UART_RING_BUFFER_ENABLE"])

    # Add DMA support if Peripheral DMA Controller (PDC) exist in the UART register group
    uartRegisterGroup = ATDF.getNode("/avr-tools-device-file/modules/module@[name=\"UART\"]/register-group@[name=\"UART\"]")
    uartRegisterList = uartRegisterGroup.getChildren()

    for index in range(0, len(uartRegisterList)):
        if (uartRegisterList[index].getAttribute("name") == "UART_RPR"):
            uartRxDMAEnable = uartComponent.createBooleanSymbol("USE_UART_RX_DMA", None)
            uartRxDMAEnable.setLabel("Enable DMA for Receive")
            uartRxDMAEnable.setVisible(True)
            uartRxDMAEnable.setDependencies(updateUARTDMAConfigurationVisbleProperty, ["USART_INTERRUPT_MODE"])
            break

    for index in range(0, len(uartRegisterList)):
        if (uartRegisterList[index].getAttribute("name") == "UART_TPR"):
            uartTxDMAEnable = uartComponent.createBooleanSymbol("USE_UART_TX_DMA", None)
            uartTxDMAEnable.setLabel("Enable DMA for Transmit")
            uartTxDMAEnable.setVisible(True)
            uartTxDMAEnable.setDependencies(updateUARTDMAConfigurationVisbleProperty, ["USART_INTERRUPT_MODE"])
            break

    uart_clock = []
    node = ATDF.getNode("/avr-tools-device-file/devices/device/peripherals/module@[name=\"UART\"]/instance@[name=\"" + uartInstanceName.getValue() + "\"]/parameters")
    uart_clock = node.getChildren()

    uartClkSrc = uartComponent.createKeyValueSetSymbol("UART_CLK_SRC", None)
    uartClkSrc.setLabel("Select Clock Source")

    for clock in range(0, len(uart_clock)):
        if ("BRSRCCK" in uart_clock[clock].getAttribute("name")):
            name_split = uart_clock[clock].getAttribute("name").split("_")[1:]
            name = "_".join(name_split)
            uartClkSrc.addKey(name, uart_clock[clock].getAttribute("value"), uart_clock[clock].getAttribute("caption"))

    uartClkSrc.setDisplayMode("Description")
    uartClkSrc.setOutputMode("Key")
    uartClkSrc.setDefaultValue(0)
    uartClkSrc.setVisible(uartClkSrc.getKeyCount() > 0)

    uartClkValue = uartComponent.createIntegerSymbol("UART_CLOCK_FREQ", None)
    uartClkValue.setLabel("Clock Frequency")
    uartClkValue.setReadOnly(True)
    uartClkValue.setDependencies(clockSourceFreq, ["UART_CLK_SRC", "core." + uartInstanceName.getValue() + "_CLOCK_FREQUENCY"])
    uartClkValue.setDefaultValue(int(Database.getSymbolValue("core", uartInstanceName.getValue() + "_CLOCK_FREQUENCY")))

    uartBaud = uartComponent.createIntegerSymbol("BAUD_RATE", None)
    uartBaud.setLabel("Baud Rate")
    uartBaud.setDefaultValue(115200)

    uartClockInvalidSym = uartComponent.createCommentSymbol("UART_CLOCK_INVALID", None)
    uartClockInvalidSym.setLabel("Warning!!! Configured baud rate cannot be acheived using current source clock frequency !!!")
    uartClockInvalidSym.setVisible(False)

    brgVal = baudRateCalc(uartClkValue.getValue(), uartBaud.getValue())

    uartBRGValue = uartComponent.createIntegerSymbol("BRG_VALUE", None)
    uartBRGValue.setVisible(False)
    uartBRGValue.setDependencies(baudRateTrigger, ["BAUD_RATE", "core." + uartInstanceName.getValue() + "_CLOCK_FREQUENCY"])
    uartBRGValue.setDefaultValue(brgVal)

    uartDataWidth = uartComponent.createComboSymbol("UART_MR_DATA_WIDTH", None, ["8 BIT"])
    uartDataWidth.setLabel("Data")
    uartDataWidth.setDefaultValue("8_BIT")
    uartDataWidth.setReadOnly(True)

    #UART Character Size 8 Mask
    uartDataWidth_8_Mask = uartComponent.createStringSymbol("USART_DATA_8_BIT_MASK", None)
    uartDataWidth_8_Mask.setDefaultValue("0x0")
    uartDataWidth_8_Mask.setVisible(False)

    uartValGrp_MR_PAR = ATDF.getNode('/avr-tools-device-file/modules/module@[name="UART"]/value-group@[name="UART_MR__PAR"]')
    parityList = []
    for id in range(0, len(uartValGrp_MR_PAR.getChildren())):
        parityList.append(id + 1)
        parityList[id] = uartValGrp_MR_PAR.getChildren()[id].getAttribute("name")

    uartSym_MR_PAR = uartComponent.createComboSymbol("UART_MR_PAR", None, parityList)
    uartSym_MR_PAR.setLabel("Parity")
    uartSym_MR_PAR.setDefaultValue("NO")

    #UART Transmit data register
    transmitRegister = uartComponent.createStringSymbol("TRANSMIT_DATA_REGISTER", None)
    transmitRegister.setDefaultValue("&("+uartInstanceName.getValue()+"_REGS->UART_THR)")
    transmitRegister.setVisible(False)

    #UART Receive data register
    receiveRegister = uartComponent.createStringSymbol("RECEIVE_DATA_REGISTER", None)
    receiveRegister.setDefaultValue("&("+uartInstanceName.getValue()+"_REGS->UART_RHR)")
    receiveRegister.setVisible(False)

    #UART EVEN Parity Mask
    uartSym_MR_PAR_EVEN_Mask = uartComponent.createStringSymbol("USART_PARITY_EVEN_MASK", None)
    uartSym_MR_PAR_EVEN_Mask.setDefaultValue("0x0")
    uartSym_MR_PAR_EVEN_Mask.setVisible(False)

    #UART ODD Parity Mask
    uartSym_MR_PAR_ODD_Mask = uartComponent.createStringSymbol("USART_PARITY_ODD_MASK", None)
    uartSym_MR_PAR_ODD_Mask.setDefaultValue("0x200")
    uartSym_MR_PAR_ODD_Mask.setVisible(False)

    #UART SPACE Parity Mask
    uartSym_MR_PAR_SPACE_Mask = uartComponent.createStringSymbol("USART_PARITY_SPACE_MASK", None)
    uartSym_MR_PAR_SPACE_Mask.setDefaultValue("0x400")
    uartSym_MR_PAR_SPACE_Mask.setVisible(False)

    #UART MARK Parity Mask
    uartSym_MR_PAR_MARK_Mask = uartComponent.createStringSymbol("USART_PARITY_MARK_MASK", None)
    uartSym_MR_PAR_MARK_Mask.setDefaultValue("0x600")
    uartSym_MR_PAR_MARK_Mask.setVisible(False)

    #UART NO Parity Mask
    uartSym_MR_PAR_NO_Mask = uartComponent.createStringSymbol("USART_PARITY_NONE_MASK", None)
    uartSym_MR_PAR_NO_Mask.setDefaultValue("0x800")
    uartSym_MR_PAR_NO_Mask.setVisible(False)

    uartStopBit = uartComponent.createComboSymbol("UART_MR_STOP_BITS", None, ["1 BIT"])
    uartStopBit.setLabel("Stop")
    uartStopBit.setDefaultValue("1_BIT")
    uartStopBit.setReadOnly(True)

    #UART Stop 1-bit Mask
    uartStopBit_1_Mask = uartComponent.createStringSymbol("USART_STOP_1_BIT_MASK", None)
    uartStopBit_1_Mask.setDefaultValue("0x0")
    uartStopBit_1_Mask.setVisible(False)

    uartSym_MR_FILTER = uartComponent.createBooleanSymbol("UART_MR_FILTER", None)
    uartSym_MR_FILTER.setLabel("Receiver Digital Filter")
    uartSym_MR_FILTER.setDefaultValue(False)

    #USART Overrun error Mask
    uartSym_SR_OVRE_Mask = uartComponent.createStringSymbol("USART_OVERRUN_ERROR_VALUE", None)
    uartSym_SR_OVRE_Mask.setDefaultValue("0x20")
    uartSym_SR_OVRE_Mask.setVisible(False)

    #USART parity error Mask
    uartSym_SR_PARE_Mask = uartComponent.createStringSymbol("USART_PARITY_ERROR_VALUE", None)
    uartSym_SR_PARE_Mask.setDefaultValue("0x80")
    uartSym_SR_PARE_Mask.setVisible(False)

    #USART framing error Mask
    uartSym_SR_FRAME_Mask = uartComponent.createStringSymbol("USART_FRAMING_ERROR_VALUE", None)
    uartSym_SR_FRAME_Mask.setDefaultValue("0x40")
    uartSym_SR_FRAME_Mask.setVisible(False)

    #UART API Prefix
    uartSym_API_Prefix = uartComponent.createStringSymbol("USART_PLIB_API_PREFIX", None)
    uartSym_API_Prefix.setDefaultValue(uartInstanceName.getValue())
    uartSym_API_Prefix.setVisible(False)

    ############################################################################
    #### Dependency ####
    ############################################################################

    interruptVector = uartInstanceName.getValue() + "_INTERRUPT_ENABLE"
    interruptHandler = uartInstanceName.getValue() + "_INTERRUPT_HANDLER"
    interruptHandlerLock = uartInstanceName.getValue() + "_INTERRUPT_HANDLER_LOCK"
    interruptVectorUpdate = uartInstanceName.getValue() + "_INTERRUPT_ENABLE_UPDATE"

    # Initial settings for CLK and NVIC
    Database.clearSymbolValue("core", uartInstanceName.getValue() + "_CLOCK_ENABLE")
    Database.setSymbolValue("core", uartInstanceName.getValue() + "_CLOCK_ENABLE", True, 2)
    Database.clearSymbolValue("core", interruptVector)
    Database.setSymbolValue("core", interruptVector, True, 2)
    Database.clearSymbolValue("core", interruptHandler)
    Database.setSymbolValue("core", interruptHandler, uartInstanceName.getValue() + "_InterruptHandler", 2)
    Database.clearSymbolValue("core", interruptHandlerLock)
    Database.setSymbolValue("core", interruptHandlerLock, True, 2)

    # NVIC Dynamic settings
    uartinterruptControl = uartComponent.createBooleanSymbol("NVIC_UART_ENABLE", None)
    uartinterruptControl.setDependencies(interruptControl, ["USART_INTERRUPT_MODE"])
    uartinterruptControl.setVisible(False)

    # Dependency Status
    uartSymClkEnComment = uartComponent.createCommentSymbol("UART_CLK_ENABLE_COMMENT", None)
    uartSymClkEnComment.setVisible(False)
    uartSymClkEnComment.setLabel("Warning!!! UART Peripheral Clock is Disabled in Clock Manager")
    uartSymClkEnComment.setDependencies(dependencyStatus, ["core." + uartInstanceName.getValue() + "_CLOCK_ENABLE"])

    uartSymIntEnComment = uartComponent.createCommentSymbol("UART_NVIC_ENABLE_COMMENT", None)
    uartSymIntEnComment.setVisible(False)
    uartSymIntEnComment.setLabel("Warning!!! UART Interrupt is Disabled in Interrupt Manager")
    uartSymIntEnComment.setDependencies(dependencyStatus, ["core." + interruptVectorUpdate])

    ############################################################################
    #### Code Generation ####
    ############################################################################

    configName = Variables.get("__CONFIGURATION_NAME")

    uartHeaderFile = uartComponent.createFileSymbol("UART_HEADER", None)
    uartHeaderFile.setSourcePath("../peripheral/uart_6418/templates/plib_uart_common.h")
    uartHeaderFile.setOutputName("plib_uart_common.h")
    uartHeaderFile.setDestPath("/peripheral/uart/")
    uartHeaderFile.setProjectPath("config/" + configName + "/peripheral/uart/")
    uartHeaderFile.setType("HEADER")
    uartHeaderFile.setOverwrite(True)

    uartHeader1File = uartComponent.createFileSymbol("UART_HEADER1", None)
    uartHeader1File.setSourcePath("../peripheral/uart_6418/templates/plib_uart.h.ftl")
    uartHeader1File.setOutputName("plib_"+uartInstanceName.getValue().lower()+ ".h")
    uartHeader1File.setDestPath("/peripheral/uart/")
    uartHeader1File.setProjectPath("config/" + configName + "/peripheral/uart/")
    uartHeader1File.setType("HEADER")
    uartHeader1File.setOverwrite(True)
    uartHeader1File.setMarkup(True)
    uartHeader1File.setDependencies(UARTFileGeneration, ["UART_RING_BUFFER_ENABLE"])

    uartSource1File = uartComponent.createFileSymbol("UART_SOURCE1", None)
    uartSource1File.setSourcePath("../peripheral/uart_6418/templates/plib_uart.c.ftl")
    uartSource1File.setOutputName("plib_"+uartInstanceName.getValue().lower()+ ".c")
    uartSource1File.setDestPath("/peripheral/uart/")
    uartSource1File.setProjectPath("config/" + configName + "/peripheral/uart/")
    uartSource1File.setType("SOURCE")
    uartSource1File.setOverwrite(True)
    uartSource1File.setMarkup(True)
    uartSource1File.setDependencies(UARTFileGeneration, ["UART_RING_BUFFER_ENABLE"])

    uartSystemInitFile = uartComponent.createFileSymbol("UART_INIT", None)
    uartSystemInitFile.setType("STRING")
    uartSystemInitFile.setOutputName("core.LIST_SYSTEM_INIT_C_SYS_INITIALIZE_PERIPHERALS")
    uartSystemInitFile.setSourcePath("../peripheral/uart_6418/templates/system/initialization.c.ftl")
    uartSystemInitFile.setMarkup(True)

    uartSystemDefFile = uartComponent.createFileSymbol("UART_DEF", None)
    uartSystemDefFile.setType("STRING")
    uartSystemDefFile.setOutputName("core.LIST_SYSTEM_DEFINITIONS_H_INCLUDES")
    uartSystemDefFile.setSourcePath("../peripheral/uart_6418/templates/system/definitions.h.ftl")
    uartSystemDefFile.setMarkup(True)
