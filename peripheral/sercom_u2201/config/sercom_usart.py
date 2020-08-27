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

###################################################################################################
###################################### BAUD Calculation ###########################################
###################################################################################################

global getUSARTBaudValue

def getUSARTBaudValue():

    global desiredUSARTBaudRate
    global usartSym_CTRLA_FORM

    baudValue = 0
    sampleCount = 0
    sampleRate = 0
    desiredUSARTBaudRate = True

    refClkFreq = int(Database.getSymbolValue("core", sercomClkFrequencyId))
    baudRate = int(Database.getSymbolValue(sercomInstanceName.getValue().lower(), "USART_BAUD_RATE"))

    frameFormat = usartSym_CTRLA_FORM.getSelectedKey()

    if refClkFreq != 0:
        if sampleRateSupported == False:
            # Check if baudrate is outside of valid range
            if refClkFreq >= (16 * baudRate):
                sampleCount = 16
            else:
                desiredUSARTBaudRate = False
        else:
            # Check if baudrate is outside of valid range
            if frameFormat == "USART_FRAME_LIN_MASTER_MODE" or frameFormat == "USART_FRAME_AUTO_BAUD_NO_PARITY" or frameFormat == "USART_FRAME_AUTO_BAUD_WITH_PARITY":
                if refClkFreq >= (16 * baudRate):
                    sampleRate = 1
                    sampleCount = 16
                else:
                    desiredUSARTBaudRate = False
            else:
                if refClkFreq >= (16 * baudRate):
                    sampleRate = 0
                    sampleCount = 16
                elif refClkFreq >= (8 * baudRate):
                    sampleRate = 2
                    sampleCount = 8
                elif refClkFreq >= (3 * baudRate):
                    sampleRate = 4
                    sampleCount = 3
                else:
                    desiredUSARTBaudRate = False

        if desiredUSARTBaudRate == True:

            usartSym_BaudError_Comment.setVisible(False)

            if frameFormat == "USART_FRAME_LIN_MASTER_MODE" or frameFormat == "USART_FRAME_AUTO_BAUD_NO_PARITY" or frameFormat == "USART_FRAME_AUTO_BAUD_WITH_PARITY":
                baudValue = float(refClkFreq)/(float(sampleCount) * baudRate)
                fp = int((float(baudValue) - int(baudValue)) * 8.0)
                baudValue = int(baudValue)
                if (baudValue == 0) or (baudValue >= 8192):
                    desiredUSARTBaudRate = False
                    usartSym_BaudError_Comment.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT")
                else:
                    baudValue |= (fp << 13)
            else:
                baudValue = int(65536 * (1 - float("{0:.15f}".format(float(sampleCount * baudRate) / refClkFreq))))

            if sampleRateSupported == True:
                usartSym_CTRLA_SAMPR.setValue(sampleRate, 1)
                usartSym_SAMPLE_COUNT.setValue(sampleCount, 1)
        else:
            usartSym_BaudError_Comment.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT")
    else:
        desiredUSARTBaudRate = False
        usartSym_BaudError_Comment.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT")

    return baudValue

###################################################################################################
########################################## Callbacks  #############################################
###################################################################################################

def updateRingBufferSizeVisibleProperty(symbol, event):
    global usartSym_RingBuffer_Enable
    global usartSym_CTRLB_RXEN
    global usartSym_CTRLB_TXEN
    global usartSym_Interrupt_Mode

    # Enable RX ring buffer size option if Ring buffer is enabled and RX is enabled.
    if symbol.getID() == "USART_RX_RING_BUFFER_SIZE":
        if ((sercomSym_OperationMode.getSelectedKey() == "USART_INT") and (usartSym_CTRLB_RXEN.getValue() == True)):
            symbol.setVisible(usartSym_RingBuffer_Enable.getValue())
        else:
            symbol.setVisible(False)
    # Enable TX ring buffer size option if Ring buffer is enabled and TX is enabled.
    elif symbol.getID() == "USART_TX_RING_BUFFER_SIZE":
        if ((sercomSym_OperationMode.getSelectedKey() == "USART_INT") and (usartSym_CTRLB_TXEN.getValue() == True)):
            symbol.setVisible(usartSym_RingBuffer_Enable.getValue())
        else:
            symbol.setVisible(False)
    # If Interrupt is enabled, make ring buffer option visible
    # Further, if Interrupt is disabled, disable the ring buffer mode
    elif symbol.getID() == "USART_RING_BUFFER_ENABLE":
        if (sercomSym_OperationMode.getSelectedKey() == "USART_INT"):
            symbol.setVisible(usartSym_Interrupt_Mode.getValue())
        else:
            symbol.setVisible(False)
        if (usartSym_Interrupt_Mode.getValue() == False):
            readOnlyState = symbol.getReadOnly()
            symbol.setReadOnly(True)
            symbol.setValue(False)
            symbol.setReadOnly(readOnlyState)

def updateUSARTConfigurationVisibleProperty(symbol, event):

    global desiredUSARTBaudRate

    if symbol.getID() == "USART_BAUD_ERROR_COMMENT":
        symbol.setVisible(desiredUSARTBaudRate == False and sercomSym_OperationMode.getSelectedKey() == "USART_INT")
    else:
        symbol.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT")

def updateUSARTBaudValueProperty(symbol, event):

    symbol.setValue(getUSARTBaudValue(), 1)

def updateUSARTRS485GuardTimeValueProperty(symbol, event):

    usart_frame_format = event['source'].getSymbolByID("USART_FORM").getSelectedKey()

    symbol.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT" and usartSym_CTRLA_TXPO.getSelectedValue() == "0x3" and (usart_frame_format == "USART_FRAME_NO_PARITY" or usart_frame_format == "USART_FRAME_WITH_PARITY"))

def updateUSARTFORMValueProperty(symbol, event):

    symbol.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT")

    if event["id"] == "USART_PARITY_MODE":

        if event["symbol"].getSelectedKey() == "NONE":
            if symbol.getValue() == 1:
                symbol.setReadOnly(True)
                symbol.setValue(0)
                symbol.setReadOnly(False)
        else:
            if symbol.getValue() == 0:
                symbol.setReadOnly(True)
                symbol.setValue(1)
                symbol.setReadOnly(False)

    if event["id"] == "USART_FORM":
            usart_form = event['source'].getSymbolByID("USART_FORM").getSelectedKey()
            usart_interrupt_mode = event['source'].getSymbolByID("USART_INTERRUPT_MODE")
            usart_ring_buffer_mode = event['source'].getSymbolByID("USART_RING_BUFFER_ENABLE")
            if usart_form == "USART_FRAME_AUTO_BAUD_NO_PARITY":
                usart_interrupt_mode.setReadOnly(True)
                usart_interrupt_mode.setValue(True)
                usart_ring_buffer_mode.setReadOnly(True)
                usart_ring_buffer_mode.setValue(True)
            else:
                usart_interrupt_mode.setReadOnly(False)
                usart_ring_buffer_mode.setReadOnly(False)




def updateLinMasterModeOptionsVisibility(symbol, event):

    symbol.setVisible(event["symbol"].getSelectedKey() == "USART_FRAME_LIN_MASTER_MODE")

###################################################################################################
############################################ USART ################################################
###################################################################################################

global usartSym_Interrupt_Mode
global usartSym_CTRLA_TXPO
global usartSym_CTRLA_SAMPR
global usartSym_SAMPLE_COUNT
global usartSym_BAUD_VALUE
global usartSym_BaudError_Comment
global sampleRateSupported
global usartSym_RingBuffer_Enable
global usartSym_CTRLB_RXEN
global usartSym_CTRLB_TXEN
global usartSym_CTRLA_FORM

sampleRateSupported = False
isFlowControlSupported = False
isRS485Supported = False
isErrorInterruptSupported = False

#Interrupt/Non-Interrupt Mode
usartSym_Interrupt_Mode = sercomComponent.createBooleanSymbol("USART_INTERRUPT_MODE", sercomSym_OperationMode)
usartSym_Interrupt_Mode.setLabel("Enable Interrupts ?")
usartSym_Interrupt_Mode.setDefaultValue(True)
usartSym_Interrupt_Mode.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT")
usartSym_Interrupt_Mode.setDependencies(updateUSARTConfigurationVisibleProperty, ["SERCOM_MODE"])

#Receive Enable
usartSym_CTRLB_RXEN = sercomComponent.createBooleanSymbol("USART_RX_ENABLE", sercomSym_OperationMode)
usartSym_CTRLB_RXEN.setLabel("Receive Enable")
usartSym_CTRLB_RXEN.setDefaultValue(True)
usartSym_CTRLB_RXEN.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT")
usartSym_CTRLB_RXEN.setDependencies(updateUSARTConfigurationVisibleProperty, ["SERCOM_MODE"])

#Transmit Enable
usartSym_CTRLB_TXEN = sercomComponent.createBooleanSymbol("USART_TX_ENABLE", sercomSym_OperationMode)
usartSym_CTRLB_TXEN.setLabel("Transmit Enable")
usartSym_CTRLB_TXEN.setDefaultValue(True)
usartSym_CTRLB_TXEN.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT")
usartSym_CTRLB_TXEN.setDependencies(updateUSARTConfigurationVisibleProperty, ["SERCOM_MODE"])

#Enable Ring buffer?
usartSym_RingBuffer_Enable = sercomComponent.createBooleanSymbol("USART_RING_BUFFER_ENABLE", sercomSym_OperationMode)
usartSym_RingBuffer_Enable.setLabel("Enable Ring Buffer ?")
usartSym_RingBuffer_Enable.setDefaultValue(False)
usartSym_RingBuffer_Enable.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT")
usartSym_RingBuffer_Enable.setDependencies(updateRingBufferSizeVisibleProperty, ["SERCOM_MODE", "USART_INTERRUPT_MODE"])

usartSym_TXRingBuffer_Size = sercomComponent.createIntegerSymbol("USART_TX_RING_BUFFER_SIZE", usartSym_RingBuffer_Enable)
usartSym_TXRingBuffer_Size.setLabel("TX Ring Buffer Size")
usartSym_TXRingBuffer_Size.setMin(2)
usartSym_TXRingBuffer_Size.setMax(65535)
usartSym_TXRingBuffer_Size.setDefaultValue(128)
usartSym_TXRingBuffer_Size.setVisible(False)
usartSym_TXRingBuffer_Size.setDependencies(updateRingBufferSizeVisibleProperty, ["SERCOM_MODE", "USART_RING_BUFFER_ENABLE", "USART_TX_ENABLE"])

usartSym_RXRingBuffer_Size = sercomComponent.createIntegerSymbol("USART_RX_RING_BUFFER_SIZE", usartSym_RingBuffer_Enable)
usartSym_RXRingBuffer_Size.setLabel("RX Ring Buffer Size")
usartSym_RXRingBuffer_Size.setMin(2)
usartSym_RXRingBuffer_Size.setMax(65535)
usartSym_RXRingBuffer_Size.setDefaultValue(128)
usartSym_RXRingBuffer_Size.setVisible(False)
usartSym_RXRingBuffer_Size.setDependencies(updateRingBufferSizeVisibleProperty, ["SERCOM_MODE", "USART_RING_BUFFER_ENABLE", "USART_RX_ENABLE"])

#USART Frame Format
isLINMasterModeSupported = False
usartSym_CTRLA_FORM = sercomComponent.createKeyValueSetSymbol("USART_FORM", sercomSym_OperationMode)
usartSym_CTRLA_FORM.setLabel("Frame Format")

usartSym_CTRLA_FORM_Node = ATDF.getNode("/avr-tools-device-file/modules/module@[name=\"SERCOM\"]/value-group@[name=\"SERCOM_USART_CTRLA__FORM\"]")
usartSym_CTRLA_FORM_Values = usartSym_CTRLA_FORM_Node.getChildren()

for index in range(len(usartSym_CTRLA_FORM_Values)):
    form_value = usartSym_CTRLA_FORM_Values[index].getAttribute("value")
    if form_value == "0x2":
        isLINMasterModeSupported = True
    if form_value <= "0x4":
        usartSym_CTRLA_FORM_Key_Name = usartSym_CTRLA_FORM_Values[index].getAttribute("name")
        usartSym_CTRLA_FORM_Key_Description = usartSym_CTRLA_FORM_Values[index].getAttribute("caption")
        usartSym_CTRLA_FORM_Key_Value = usartSym_CTRLA_FORM_Values[index].getAttribute("value")
        usartSym_CTRLA_FORM.addKey(usartSym_CTRLA_FORM_Key_Name, usartSym_CTRLA_FORM_Key_Value, usartSym_CTRLA_FORM_Key_Description)

usartSym_CTRLA_FORM.setDefaultValue(0)
usartSym_CTRLA_FORM.setOutputMode("Value")
usartSym_CTRLA_FORM.setDisplayMode("Description")
usartSym_CTRLA_FORM.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT")
usartSym_CTRLA_FORM.setDependencies(updateUSARTFORMValueProperty, ["USART_PARITY_MODE", "SERCOM_MODE", "USART_FORM"])

#USART LIN Master Mode Support
usartSym_LIN_MasterSupport = sercomComponent.createBooleanSymbol("USART_LIN_MASTER_SUPPORTED", sercomSym_OperationMode)
usartSym_LIN_MasterSupport.setValue(isLINMasterModeSupported)
usartSym_LIN_MasterSupport.setVisible(False)


# BREAK Length - Applicable when LIN Master mode is selected
usartSym_CTRLC_BRKLEN_Node = ATDF.getNode("/avr-tools-device-file/modules/module@[name=\"SERCOM\"]/value-group@[name=\"SERCOM_USART_CTRLC__BRKLEN\"]")

if usartSym_CTRLC_BRKLEN_Node != None:
    usartSym_CTRLC_BRKLEN = sercomComponent.createKeyValueSetSymbol("USART_LIN_MASTER_BREAK_LEN", sercomSym_OperationMode)
    usartSym_CTRLC_BRKLEN.setLabel("LIN Master Break Length")
    usartSym_CTRLC_BRKLEN_Values = usartSym_CTRLC_BRKLEN_Node.getChildren()

    for index in range(len(usartSym_CTRLC_BRKLEN_Values)):
        form_value = usartSym_CTRLC_BRKLEN_Values[index].getAttribute("value")
        if form_value <= "0x5":
            usartSym_CTRLC_BRKLEN_Key_Name = usartSym_CTRLC_BRKLEN_Values[index].getAttribute("name")
            usartSym_CTRLC_BRKLEN_Key_Description = usartSym_CTRLC_BRKLEN_Values[index].getAttribute("caption")
            usartSym_CTRLC_BRKLEN_Key_Value = usartSym_CTRLC_BRKLEN_Values[index].getAttribute("value")
            usartSym_CTRLC_BRKLEN.addKey(usartSym_CTRLC_BRKLEN_Key_Name, usartSym_CTRLC_BRKLEN_Key_Value, usartSym_CTRLC_BRKLEN_Key_Description)

    usartSym_CTRLC_BRKLEN.setDefaultValue(0)
    usartSym_CTRLC_BRKLEN.setOutputMode("Value")
    usartSym_CTRLC_BRKLEN.setDisplayMode("Description")
    usartSym_CTRLC_BRKLEN.setVisible(False)
    usartSym_CTRLC_BRKLEN.setDependencies(updateLinMasterModeOptionsVisibility, ["USART_FORM"])

# Hardware Delay - Applicable when LIN Master mode is selected
usartSym_CTRLC_HDRDLY_Node = ATDF.getNode("/avr-tools-device-file/modules/module@[name=\"SERCOM\"]/value-group@[name=\"SERCOM_USART_CTRLC__HDRDLY\"]")

if usartSym_CTRLC_HDRDLY_Node != None:
    usartSym_CTRLC_HDRDLY = sercomComponent.createKeyValueSetSymbol("USART_LIN_MASTER_HDRDLY", sercomSym_OperationMode)
    usartSym_CTRLC_HDRDLY.setLabel("LIN Master Hardware Delay")
    usartSym_CTRLC_HDRDLY_Values = usartSym_CTRLC_HDRDLY_Node.getChildren()

    for index in range(len(usartSym_CTRLC_HDRDLY_Values)):
        form_value = usartSym_CTRLC_HDRDLY_Values[index].getAttribute("value")
        if form_value <= "0x5":
            usartSym_CTRLC_HDRDLY_Key_Name = usartSym_CTRLC_HDRDLY_Values[index].getAttribute("name")
            usartSym_CTRLC_HDRDLY_Key_Description = usartSym_CTRLC_HDRDLY_Values[index].getAttribute("caption")
            usartSym_CTRLC_HDRDLY_Key_Value = usartSym_CTRLC_HDRDLY_Values[index].getAttribute("value")
            usartSym_CTRLC_HDRDLY.addKey(usartSym_CTRLC_HDRDLY_Key_Name, usartSym_CTRLC_HDRDLY_Key_Value, usartSym_CTRLC_HDRDLY_Key_Description)

    usartSym_CTRLC_HDRDLY.setDefaultValue(0)
    usartSym_CTRLC_HDRDLY.setOutputMode("Value")
    usartSym_CTRLC_HDRDLY.setDisplayMode("Description")
    usartSym_CTRLC_HDRDLY.setVisible(False)
    usartSym_CTRLC_HDRDLY.setDependencies(updateLinMasterModeOptionsVisibility, ["USART_FORM"])

#Run in StandBy
usartSym_CTRLA_RUNSTDBY = sercomComponent.createBooleanSymbol("USART_RUNSTDBY", sercomSym_OperationMode)
usartSym_CTRLA_RUNSTDBY.setLabel("Enable Run in Standby")
usartSym_CTRLA_RUNSTDBY.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT")
usartSym_CTRLA_RUNSTDBY.setDependencies(updateUSARTConfigurationVisibleProperty, ["SERCOM_MODE"])

#RXPO - Receive Pin Out
usartSym_CTRLA_RXPO = sercomComponent.createKeyValueSetSymbol("USART_RXPO", sercomSym_OperationMode)
usartSym_CTRLA_RXPO.setLabel("Receive Pinout")

usartSym_CTRLA_RXPO_Node = ATDF.getNode("/avr-tools-device-file/modules/module@[name=\"SERCOM\"]/value-group@[name=\"SERCOM_USART_CTRLA__RXPO\"]")
usartSym_CTRLA_RXPO_Values = usartSym_CTRLA_RXPO_Node.getChildren()

for index in range(len(usartSym_CTRLA_RXPO_Values)):
    usartSym_CTRLA_RXPO_Key_Name = usartSym_CTRLA_RXPO_Values[index].getAttribute("name")
    usartSym_CTRLA_RXPO_Key_Description = usartSym_CTRLA_RXPO_Values[index].getAttribute("caption")
    usartSym_CTRLA_RXPO_Key_Value = usartSym_CTRLA_RXPO_Values[index].getAttribute("value")
    usartSym_CTRLA_RXPO.addKey(usartSym_CTRLA_RXPO_Key_Name, usartSym_CTRLA_RXPO_Key_Value, usartSym_CTRLA_RXPO_Key_Description)

usartSym_CTRLA_RXPO.setDefaultValue(0)
usartSym_CTRLA_RXPO.setOutputMode("Value")
usartSym_CTRLA_RXPO.setDisplayMode("Description")
usartSym_CTRLA_RXPO.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT")
usartSym_CTRLA_RXPO.setDependencies(updateUSARTConfigurationVisibleProperty, ["SERCOM_MODE"])

#TXPO - Transmit Pin Out
usartSym_CTRLA_TXPO = sercomComponent.createKeyValueSetSymbol("USART_TXPO", sercomSym_OperationMode)
usartSym_CTRLA_TXPO.setLabel("Transmit Pinout")

usartSym_CTRLA_TXPO_Node = ATDF.getNode("/avr-tools-device-file/modules/module@[name=\"SERCOM\"]/value-group@[name=\"SERCOM_USART_CTRLA__TXPO\"]")
usartSym_CTRLA_TXPO_Values = usartSym_CTRLA_TXPO_Node.getChildren()

for index in range(len(usartSym_CTRLA_TXPO_Values)):
    usartSym_CTRLA_TXPO_Key_Name = usartSym_CTRLA_TXPO_Values[index].getAttribute("name")
    usartSym_CTRLA_TXPO_Key_Description = usartSym_CTRLA_TXPO_Values[index].getAttribute("caption")
    usartSym_CTRLA_TXPO_Key_Value = usartSym_CTRLA_TXPO_Values[index].getAttribute("value")
    usartSym_CTRLA_TXPO.addKey(usartSym_CTRLA_TXPO_Key_Name, usartSym_CTRLA_TXPO_Key_Value, usartSym_CTRLA_TXPO_Key_Description)

    if int(usartSym_CTRLA_TXPO_Key_Value, 0) == 2:
        isFlowControlSupported = True
    if int(usartSym_CTRLA_TXPO_Key_Value, 0) == 3:
        isRS485Supported = True

usartSym_CTRLA_TXPO.setDefaultValue(0)
usartSym_CTRLA_TXPO.setOutputMode("Value")
usartSym_CTRLA_TXPO.setDisplayMode("Description")
usartSym_CTRLA_TXPO.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT")
usartSym_CTRLA_TXPO.setDependencies(updateUSARTConfigurationVisibleProperty, ["SERCOM_MODE"])

if isRS485Supported == True:
    #USART RS485 mode Guard Time
    usartSym_CTRLC_GTIME = sercomComponent.createIntegerSymbol("USART_CTRLC_GTIME", sercomSym_OperationMode)
    usartSym_CTRLC_GTIME.setLabel("RS485 Guard Time")
    usartSym_CTRLC_GTIME.setDefaultValue(0)
    usartSym_CTRLC_GTIME.setMin(0)
    usartSym_CTRLC_GTIME.setMax(7)
    usartSym_CTRLC_GTIME.setVisible(False)
    usartSym_CTRLC_GTIME.setDependencies(updateUSARTRS485GuardTimeValueProperty, ["SERCOM_MODE", "USART_TXPO" , "USART_FORM"])

#PMODE : USART PARITY MODE
usartSym_CTRLB_PMODE = sercomComponent.createKeyValueSetSymbol("USART_PARITY_MODE", sercomSym_OperationMode)
usartSym_CTRLB_PMODE.setLabel("Parity Mode")
usartSym_CTRLB_PMODE.addKey("EVEN", "0x0", "Even Parity")
usartSym_CTRLB_PMODE.addKey("ODD", "0x1", "Odd Parity")
usartSym_CTRLB_PMODE.addKey("NONE", "0x2", "No Parity")
usartSym_CTRLB_PMODE.setDefaultValue(2)
usartSym_CTRLB_PMODE.setOutputMode("Key")
usartSym_CTRLB_PMODE.setDisplayMode("Description")
usartSym_CTRLB_PMODE.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT")
usartSym_CTRLB_PMODE.setDependencies(updateUSARTConfigurationVisibleProperty, ["SERCOM_MODE"])

#Character Size
usartSym_CTRLB_CHSIZE = sercomComponent.createKeyValueSetSymbol("USART_CHARSIZE_BITS", sercomSym_OperationMode)
usartSym_CTRLB_CHSIZE.setLabel("Character Size")

usartSym_CTRLA_CHSIZE_Node = ATDF.getNode("/avr-tools-device-file/modules/module@[name=\"SERCOM\"]/value-group@[name=\"SERCOM_USART_CTRLB__CHSIZE\"]")
usartSym_CTRLA_CHSIZE_Values = usartSym_CTRLA_CHSIZE_Node.getChildren()

for index in range(len(usartSym_CTRLA_CHSIZE_Values)):
    usartSym_CTRLB_CHSIZE_Key_Name = usartSym_CTRLA_CHSIZE_Values[index].getAttribute("name")
    usartSym_CTRLB_CHSIZE_Key_Description = usartSym_CTRLA_CHSIZE_Values[index].getAttribute("caption")
    usartSym_CTRLB_CHSIZE_Key_Value = usartSym_CTRLA_CHSIZE_Values[index].getAttribute("value")
    usartSym_CTRLB_CHSIZE.addKey(usartSym_CTRLB_CHSIZE_Key_Name, usartSym_CTRLB_CHSIZE_Key_Value, usartSym_CTRLB_CHSIZE_Key_Description)

usartSym_CTRLB_CHSIZE.setDefaultValue(0)
usartSym_CTRLB_CHSIZE.setOutputMode("Key")
usartSym_CTRLB_CHSIZE.setDisplayMode("Description")
usartSym_CTRLB_CHSIZE.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT")
usartSym_CTRLB_CHSIZE.setDependencies(updateUSARTConfigurationVisibleProperty, ["SERCOM_MODE"])

#Stop Bit
usartSym_CTRLB_SBMODE = sercomComponent.createKeyValueSetSymbol("USART_STOP_BIT", sercomSym_OperationMode)
usartSym_CTRLB_SBMODE.setLabel("Stop Bit Mode")

usartSym_CTRLA_SBMODE_Node = ATDF.getNode("/avr-tools-device-file/modules/module@[name=\"SERCOM\"]/value-group@[name=\"SERCOM_USART_CTRLB__SBMODE\"]")
usartSym_CTRLA_SBMODE_Values = usartSym_CTRLA_SBMODE_Node.getChildren()

for index in range(len(usartSym_CTRLA_SBMODE_Values)):
    usartSym_CTRLB_SBMODE_Key_Name = usartSym_CTRLA_SBMODE_Values[index].getAttribute("name")
    usartSym_CTRLB_SBMODE_Key_Description = usartSym_CTRLA_SBMODE_Values[index].getAttribute("caption")
    usartSym_CTRLB_SBMODE_Key_Value = usartSym_CTRLA_SBMODE_Values[index].getAttribute("value")
    usartSym_CTRLB_SBMODE.addKey(usartSym_CTRLB_SBMODE_Key_Name, usartSym_CTRLB_SBMODE_Key_Value, usartSym_CTRLB_SBMODE_Key_Description)

usartSym_CTRLB_SBMODE.setDefaultValue(0)
usartSym_CTRLB_SBMODE.setOutputMode("Key")
usartSym_CTRLB_SBMODE.setDisplayMode("Description")
usartSym_CTRLB_SBMODE.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT")
usartSym_CTRLB_SBMODE.setDependencies(updateUSARTConfigurationVisibleProperty, ["SERCOM_MODE"])

sampleRateNode = ATDF.getNode('/avr-tools-device-file/modules/module@[name="SERCOM"]/register-group@[name="SERCOM"]/register@[modes="USART_INT",name="CTRLA"]')
sampleRateValue = sampleRateNode.getChildren()

for index in range(len(sampleRateValue)):
    bitFieldName = str(sampleRateValue[index].getAttribute("name"))
    if bitFieldName == "SAMPR":
        sampleRateSupported = True
        break

if sampleRateSupported == True:
    #USART Over-Sampling using Baud Rate generation
    usartSym_CTRLA_SAMPR = sercomComponent.createIntegerSymbol("USART_SAMPLE_RATE", sercomSym_OperationMode)
    usartSym_CTRLA_SAMPR.setLabel("Sample Rate")
    usartSym_CTRLA_SAMPR.setDefaultValue(0)
    usartSym_CTRLA_SAMPR.setVisible(False)

#USART No Of Samples
usartSym_SAMPLE_COUNT = sercomComponent.createIntegerSymbol("USART_SAMPLE_COUNT", sercomSym_OperationMode)
usartSym_SAMPLE_COUNT.setLabel("No Of Samples")
usartSym_SAMPLE_COUNT.setDefaultValue(16)
usartSym_SAMPLE_COUNT.setVisible(False)

#USART Baud Rate
usartSym_BAUD_RATE = sercomComponent.createIntegerSymbol("USART_BAUD_RATE", sercomSym_OperationMode)
usartSym_BAUD_RATE.setLabel("Baud Rate in Hz")
usartSym_BAUD_RATE.setDefaultValue(115200)
usartSym_BAUD_RATE.setMin(1)
usartSym_BAUD_RATE.setVisible(sercomSym_OperationMode.getSelectedKey() == "USART_INT")
usartSym_BAUD_RATE.setDependencies(updateUSARTConfigurationVisibleProperty, ["SERCOM_MODE"])

#USART Baud Value
usartSym_BAUD_VALUE = sercomComponent.createIntegerSymbol("USART_BAUD_VALUE", sercomSym_OperationMode)
usartSym_BAUD_VALUE.setLabel("Baud Rate Value")
usartSym_BAUD_VALUE.setVisible(False)
usartSym_BAUD_VALUE.setDependencies(updateUSARTBaudValueProperty, ["USART_BAUD_RATE", "core." + sercomClkFrequencyId, "USART_FORM"])

#USART Baud Rate not supported comment
usartSym_BaudError_Comment = sercomComponent.createCommentSymbol("USART_BAUD_ERROR_COMMENT", sercomSym_OperationMode)
usartSym_BaudError_Comment.setLabel("********** USART Clock source value is low for the desired baud rate **********")
usartSym_BaudError_Comment.setVisible(False)
usartSym_BaudError_Comment.setDependencies(updateUSARTConfigurationVisibleProperty, ["SERCOM_MODE"])

intensetNode = ATDF.getNode('/avr-tools-device-file/modules/module@[name="SERCOM"]/register-group@[name="SERCOM"]/register@[modes="USART_INT",name="INTENSET"]')
intensetValue = intensetNode.getChildren()

for index in range(len(intensetValue)):
    bitFieldName = str(intensetValue[index].getAttribute("name"))
    if bitFieldName == "ERROR":
        isErrorInterruptSupported = True
        break

#USART is ERROR present
usartSym_ErrorInterrupt = sercomComponent.createBooleanSymbol("USART_INTENSET_ERROR", None)
usartSym_ErrorInterrupt.setVisible(False)
usartSym_ErrorInterrupt.setDefaultValue(isErrorInterruptSupported)

#USART Flow Control supported
usartSym_FlowControl = sercomComponent.createBooleanSymbol("USART_FLOW_CONTROL", None)
usartSym_FlowControl.setVisible(False)
usartSym_FlowControl.setDefaultValue(isFlowControlSupported)

#USART RS485 mode supported
usartSym_RS485 = sercomComponent.createBooleanSymbol("USART_RS485", None)
usartSym_RS485.setVisible(False)
usartSym_RS485.setDefaultValue(isRS485Supported)

#Use setValue instead of setDefaultValue to store symbol value in default.xml
usartSym_BAUD_VALUE.setValue(getUSARTBaudValue(), 1)



###################################################################################################
####################################### Driver Symbols ############################################
###################################################################################################

#USART API Prefix
usartSym_API_Prefix = sercomComponent.createStringSymbol("USART_PLIB_API_PREFIX", sercomSym_OperationMode)
usartSym_API_Prefix.setDefaultValue(sercomInstanceName.getValue() + "_USART")
usartSym_API_Prefix.setVisible(False)

#USART EVEN Parity Mask
usartSym_CTRLA_PMODE_EVEN_Mask = sercomComponent.createStringSymbol("USART_PARITY_EVEN_MASK", sercomSym_OperationMode)
usartSym_CTRLA_PMODE_EVEN_Mask.setDefaultValue("0x0")
usartSym_CTRLA_PMODE_EVEN_Mask.setVisible(False)

#USART ODD Parity Mask
usartSym_CTRLA_PMODE_ODD_Mask = sercomComponent.createStringSymbol("USART_PARITY_ODD_MASK", sercomSym_OperationMode)
usartSym_CTRLA_PMODE_ODD_Mask.setDefaultValue("0x80000")
usartSym_CTRLA_PMODE_ODD_Mask.setVisible(False)

#USART NONE Parity Mask
usartSym_Parity_NONE_Mask = sercomComponent.createStringSymbol("USART_PARITY_NONE_MASK", sercomSym_OperationMode)
usartSym_Parity_NONE_Mask.setDefaultValue("0x2")
usartSym_Parity_NONE_Mask.setVisible(False)

#USART Character Size 5 Mask
usartSym_CTRLB_CHSIZE_5_Mask = sercomComponent.createStringSymbol("USART_DATA_5_BIT_MASK", sercomSym_OperationMode)
usartSym_CTRLB_CHSIZE_5_Mask.setDefaultValue("0x5")
usartSym_CTRLB_CHSIZE_5_Mask.setVisible(False)

#USART Character Size 6 Mask
usartSym_CTRLB_CHSIZE_6_Mask = sercomComponent.createStringSymbol("USART_DATA_6_BIT_MASK", sercomSym_OperationMode)
usartSym_CTRLB_CHSIZE_6_Mask.setDefaultValue("0x6")
usartSym_CTRLB_CHSIZE_6_Mask.setVisible(False)

#USART Character Size 7 Mask
usartSym_CTRLB_CHSIZE_7_Mask = sercomComponent.createStringSymbol("USART_DATA_7_BIT_MASK", sercomSym_OperationMode)
usartSym_CTRLB_CHSIZE_7_Mask.setDefaultValue("0x7")
usartSym_CTRLB_CHSIZE_7_Mask.setVisible(False)

#USART Character Size 8 Mask
usartSym_CTRLB_CHSIZE_8_Mask = sercomComponent.createStringSymbol("USART_DATA_8_BIT_MASK", sercomSym_OperationMode)
usartSym_CTRLB_CHSIZE_8_Mask.setDefaultValue("0x0")
usartSym_CTRLB_CHSIZE_8_Mask.setVisible(False)

#USART Character Size 9 Mask
usartSym_CTRLB_CHSIZE_9_Mask = sercomComponent.createStringSymbol("USART_DATA_9_BIT_MASK", sercomSym_OperationMode)
usartSym_CTRLB_CHSIZE_9_Mask.setDefaultValue("0x1")
usartSym_CTRLB_CHSIZE_9_Mask.setVisible(False)

#USART Stop 1-bit Mask
usartSym_CTRLB_SBMODE_1_Mask = sercomComponent.createStringSymbol("USART_STOP_1_BIT_MASK", sercomSym_OperationMode)
usartSym_CTRLB_SBMODE_1_Mask.setDefaultValue("0x0")
usartSym_CTRLB_SBMODE_1_Mask.setVisible(False)

#USART Stop 2-bit Mask
usartSym_CTRLB_SBMODE_2_Mask = sercomComponent.createStringSymbol("USART_STOP_2_BIT_MASK", sercomSym_OperationMode)
usartSym_CTRLB_SBMODE_2_Mask.setDefaultValue("0x40")
usartSym_CTRLB_SBMODE_2_Mask.setVisible(False)

#USART Overrun error Mask
sercomSym_STATUS_BUFOVF_Mask = sercomComponent.createStringSymbol("USART_OVERRUN_ERROR_VALUE", sercomSym_OperationMode)
sercomSym_STATUS_BUFOVF_Mask.setDefaultValue("0x4")
sercomSym_STATUS_BUFOVF_Mask.setVisible(False)

#USART parity error Mask
sercomSym_STATUS_PERR_Mask = sercomComponent.createStringSymbol("USART_PARITY_ERROR_VALUE", sercomSym_OperationMode)
sercomSym_STATUS_PERR_Mask.setDefaultValue("0x0")
sercomSym_STATUS_PERR_Mask.setVisible(False)

#USART framing error Mask
sercomSym_STATUS_FERR_Mask = sercomComponent.createStringSymbol("USART_FRAMING_ERROR_VALUE", sercomSym_OperationMode)
sercomSym_STATUS_FERR_Mask.setDefaultValue("0x2")
sercomSym_STATUS_FERR_Mask.setVisible(False)