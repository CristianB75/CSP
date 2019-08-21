/*******************************************************************************
  ${FLEXCOM_INSTANCE_NAME} USART PLIB

  Company:
    Microchip Technology Inc.

  File Name:
    plib_${FLEXCOM_INSTANCE_NAME?lower_case}_usart.c

  Summary:
    ${FLEXCOM_INSTANCE_NAME} USART PLIB Implementation File

  Description
    This file defines the interface to the ${FLEXCOM_INSTANCE_NAME} USART
    peripheral library. This library provides access to and control of the
    associated peripheral instance.

  Remarks:
    None.
*******************************************************************************/

/*******************************************************************************
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
*******************************************************************************/

// *****************************************************************************
// *****************************************************************************
// Section: Included Files
// *****************************************************************************
// *****************************************************************************

#include "plib_${FLEXCOM_INSTANCE_NAME?lower_case}_${FLEXCOM_MODE?lower_case}.h"

// *****************************************************************************
// *****************************************************************************
// Section: ${FLEXCOM_INSTANCE_NAME} ${FLEXCOM_MODE} Implementation
// *****************************************************************************
// *****************************************************************************
<#if USART_INTERRUPT_MODE == true>

FLEXCOM_USART_OBJECT ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj;

<#if !(USE_USART_RX_DMA??) || (USE_USART_RX_DMA == false)>
void static ${FLEXCOM_INSTANCE_NAME}_USART_ISR_RX_Handler( void )
{
    if(${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxBusyStatus == true)
    {
        while((US_CSR_RXRDY_Msk == (USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_CSR & US_CSR_RXRDY_Msk)) && (${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxSize > ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxProcessedSize) )
        {
            ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxBuffer[${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxProcessedSize++] = (USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_RHR & US_RHR_RXCHR_Msk);
        }

        /* Check if the buffer is done */
        if(${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxProcessedSize >= ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxSize)
        {
            ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxBusyStatus = false;

            /* Disable Read, Overrun, Parity and Framing error interrupts */
            USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_IDR = (US_IDR_RXRDY_Msk | US_IDR_FRAME_Msk | US_IDR_PARE_Msk | US_IDR_OVRE_Msk);

            if(${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxCallback != NULL)
            {
                ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxCallback(${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxContext);
            }
        }
    }
    else
    {
        /* Nothing to process */
        ;
    }
}

</#if>
<#if !(USE_USART_TX_DMA??) || (USE_USART_TX_DMA == false)>
void static ${FLEXCOM_INSTANCE_NAME}_USART_ISR_TX_Handler( void )
{
    if(${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txBusyStatus == true)
    {
        while((US_CSR_TXEMPTY_Msk == (USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_CSR & US_CSR_TXEMPTY_Msk)) && (${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txSize > ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txProcessedSize) )
        {
            USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_THR = ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txBuffer[${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txProcessedSize++];
        }

        /* Check if the buffer is done */
        if(${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txProcessedSize >= ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txSize)
        {
            ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txBusyStatus = false;
            USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_IDR = US_IDR_TXEMPTY_Msk;

            if(${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txCallback != NULL)
            {
                ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txCallback(${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txContext);
            }
        }
    }
    else
    {
        /* Nothing to process */
        ;
    }
}
</#if>

void ${FLEXCOM_INSTANCE_NAME}_InterruptHandler( void )
{
    /* Channel status */
    uint32_t channelStatus = USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_CSR;

    <#if (USE_USART_TX_DMA?? && USE_USART_TX_DMA == true) || (USE_USART_RX_DMA?? && USE_USART_RX_DMA == true)>
    USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_PTCR = US_PTCR_ERRCLR_Msk;
    </#if>

    <#if USE_USART_RX_DMA?? && USE_USART_RX_DMA == true>
    if ((USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_PTSR & US_PTSR_RXTEN_Msk) && (channelStatus & US_CSR_ENDRX_Msk))
    {
        if(${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxBusyStatus == true)
        {
            ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxBusyStatus = false;
            USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_PTCR = US_PTCR_RXTDIS_Msk;
            USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_IDR = US_IDR_ENDRX_Msk;

            if( ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxCallback != NULL )
            {
                ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxCallback(${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxContext);
            }
        }
    }
    <#else>
    /* Error status */
    uint32_t errorStatus = (channelStatus & (US_CSR_OVRE_Msk | US_CSR_FRAME_Msk | US_CSR_PARE_Msk));

    if(errorStatus != 0)
    {
        ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxBusyStatus = false;

        /* Disable Read, Overrun, Parity and Framing error interrupts */
        USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_IDR = (US_IDR_RXRDY_Msk | US_IDR_FRAME_Msk | US_IDR_PARE_Msk | US_IDR_OVRE_Msk);

        /* Client must call ${FLEXCOM_INSTANCE_NAME}_USART_ErrorGet() function to clear the errors */

        /* USART errors are normally associated with the receiver, hence calling
         * receiver context */
        if( ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxCallback != NULL )
        {
            ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxCallback(${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxContext);
        }
    }

    /* Receiver status */
    if(US_CSR_RXRDY_Msk == (channelStatus & US_CSR_RXRDY_Msk))
    {
        ${FLEXCOM_INSTANCE_NAME}_USART_ISR_RX_Handler();
    }
    </#if>

    <#if USE_USART_TX_DMA?? && USE_USART_TX_DMA == true>
    if ((USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_PTSR & US_PTSR_TXTEN_Msk) && (channelStatus & US_CSR_ENDTX_Msk))
    {
        if(${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txBusyStatus == true)
        {
            ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txBusyStatus = false;
            USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_PTCR = US_PTCR_TXTDIS_Msk;
            USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_IDR = US_IDR_ENDTX_Msk;

            if( ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txCallback != NULL )
            {
                ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txCallback(${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txContext);
            }
        }
    }
    <#else>
    /* Transmitter status */
    if(US_CSR_TXEMPTY_Msk == (channelStatus & US_CSR_TXEMPTY_Msk))
    {
        ${FLEXCOM_INSTANCE_NAME}_USART_ISR_TX_Handler();
    }
    </#if>
}
</#if>

void static ${FLEXCOM_INSTANCE_NAME}_USART_ErrorClear( void )
{
    uint8_t dummyData = 0u;

    USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_CR = US_CR_RSTSTA_Msk;

    /* Flush existing error bytes from the RX FIFO */
    while( US_CSR_RXRDY_Msk == (USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_CSR& US_CSR_RXRDY_Msk) )
    {
        dummyData = (USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_RHR& US_RHR_RXCHR_Msk);
    }

    /* Ignore the warning */
    (void)dummyData;
}

void ${FLEXCOM_INSTANCE_NAME}_USART_Initialize( void )
{
    /* Set FLEXCOM USART operating mode */
    ${FLEXCOM_INSTANCE_NAME}_REGS->FLEXCOM_MR = FLEXCOM_MR_OPMODE_USART;

    /* Reset ${FLEXCOM_INSTANCE_NAME} USART */
    USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_CR = (US_CR_RSTRX_Msk | US_CR_RSTTX_Msk | US_CR_RSTSTA_Msk);

    /* Enable ${FLEXCOM_INSTANCE_NAME} USART */
    USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_CR = (US_CR_TXEN_Msk | US_CR_RXEN_Msk);

    /* Configure ${FLEXCOM_INSTANCE_NAME} USART mode */
    USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_MR = ((US_MR_USCLKS_${FLEXCOM_USART_MR_USCLKS}) ${(FLEX_USART_MR_MODE9 == true)?then('| US_MR_MODE9_Msk', '| US_MR_CHRL${FLEX_USART_MR_CHRL}')} | US_MR_PAR_${FLEX_USART_MR_PAR} | US_MR_NBSTOP${FLEX_USART_MR_NBSTOP} | (${FLEXCOM_USART_MR_OVER} << US_MR_OVER_Pos));

    /* Configure ${FLEXCOM_INSTANCE_NAME} USART Baud Rate */
    USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_BRGR = US_BRGR_CD(${BRG_VALUE});
<#if USART_INTERRUPT_MODE == true>

    /* Initialize instance object */
    ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxBuffer = NULL;
    ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxSize = 0;
    ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxProcessedSize = 0;
    ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxBusyStatus = false;
    ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxCallback = NULL;
    ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txBuffer = NULL;
    ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txSize = 0;
    ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txProcessedSize = 0;
    ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txBusyStatus = false;
    ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txCallback = NULL;
</#if>
}

FLEXCOM_USART_ERROR ${FLEXCOM_INSTANCE_NAME}_USART_ErrorGet( void )
{
    FLEXCOM_USART_ERROR errors = FLEXCOM_USART_ERROR_NONE;
    uint32_t status = USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_CSR;

    /* Collect all errors */
    if(status & US_CSR_OVRE_Msk)
    {
        errors = FLEXCOM_USART_ERROR_OVERRUN;
    }

    if(status & US_CSR_PARE_Msk)
    {
        errors |= FLEXCOM_USART_ERROR_PARITY;
    }

    if(status & US_CSR_FRAME_Msk)
    {
        errors |= FLEXCOM_USART_ERROR_FRAMING;
    }

    if(errors != FLEXCOM_USART_ERROR_NONE)
    {
        ${FLEXCOM_INSTANCE_NAME}_USART_ErrorClear();
    }

    /* All errors are cleared, but send the previous error state */
    return errors;
}

bool ${FLEXCOM_INSTANCE_NAME}_USART_SerialSetup( FLEXCOM_USART_SERIAL_SETUP *setup, uint32_t srcClkFreq )
{
    uint32_t baud = 0;
    uint32_t brgVal = 0;
    uint32_t overSampVal = 0;
    uint32_t usartMode;
    bool status = false;

<#if USART_INTERRUPT_MODE == true>
    if((${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxBusyStatus == true) || (${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txBusyStatus == true))
    {
        /* Transaction is in progress, so return without updating settings */
        return false;
    }

</#if>
    if (setup != NULL)
    {
        baud = setup->baudRate;

        if(srcClkFreq == 0)
        {
            srcClkFreq = ${FLEXCOM_INSTANCE_NAME}_USART_FrequencyGet();
        }

        /* Calculate BRG value */
        if (srcClkFreq >= (16 * baud))
        {
            brgVal = (srcClkFreq / (16 * baud));
        }
        else if (srcClkFreq >= (8 * baud))
        {
            brgVal = (srcClkFreq / (8 * baud));
            overSampVal = (1 << US_MR_OVER_Pos) & US_MR_OVER_Msk;
        }
        else
        {
            /* The input clock source - srcClkFreq, is too low to generate the desired baud */
            return status;
        }
        
        if (brgVal > 65535)
        {
            /* The requested baud is so low that the ratio of srcClkFreq to baud exceeds the 16-bit register value of CD register */
            return status;
        }

        /* Configure ${FLEXCOM_INSTANCE_NAME} USART mode */
        usartMode = USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_MR;
        usartMode &= ~(US_MR_CHRL_Msk | US_MR_MODE9_Msk | US_MR_PAR_Msk | US_MR_NBSTOP_Msk | US_MR_OVER_Msk);
        USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_MR = usartMode | ((uint32_t)setup->dataWidth | (uint32_t)setup->parity | (uint32_t)setup->stopBits | overSampVal);

        /* Configure ${FLEXCOM_INSTANCE_NAME} USART Baud Rate */
        USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_BRGR = US_BRGR_CD(brgVal);
        status = true;
    }

    return status;
}

bool ${FLEXCOM_INSTANCE_NAME}_USART_Read( void *buffer, const size_t size )
{
    bool status = false;
<#if USART_INTERRUPT_MODE == false>
    uint32_t errorStatus = 0;
    size_t processedSize = 0;
</#if>
    uint8_t * lBuffer = (uint8_t *)buffer;

    if(lBuffer != NULL)
    {
        /* Clear errors before submitting the request.
         * ErrorGet clears errors internally. */
        ${FLEXCOM_INSTANCE_NAME}_USART_ErrorGet();

<#if USART_INTERRUPT_MODE == false>
        while( size > processedSize )
        {
            /* Error status */
            errorStatus = (USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_CSR & (US_CSR_OVRE_Msk | US_CSR_FRAME_Msk | US_CSR_PARE_Msk));

            if(errorStatus != 0)
            {
                break;
            }

            if(US_CSR_RXRDY_Msk == (USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_CSR & US_CSR_RXRDY_Msk))
            {
                *lBuffer++ = (USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_RHR& US_RHR_RXCHR_Msk);
                processedSize++;
            }
        }

        if(size == processedSize)
        {
            status = true;
        }

<#else>
        /* Check if receive request is in progress */
        if(${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxBusyStatus == false)
        {
            status = true;

            ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxBuffer = lBuffer;
            ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxSize = size;
            ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxProcessedSize = 0;
            ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxBusyStatus = true;

            <#if USE_USART_RX_DMA?? && USE_USART_RX_DMA == true>
            USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_RPR = (uint32_t) buffer;
            USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_RCR = (uint32_t) size;
            USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_PTCR = US_PTCR_RXTEN_Msk;
            USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_IER = US_IER_ENDRX_Msk;
            <#else>

            /* Enable Read, Overrun, Parity and Framing error interrupts */
            USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_IER = (US_IER_RXRDY_Msk | US_IER_FRAME_Msk | US_IER_PARE_Msk | US_IER_OVRE_Msk);
            </#if>
        }
</#if>
    }

    return status;
}

bool ${FLEXCOM_INSTANCE_NAME}_USART_Write( void *buffer, const size_t size )
{
    bool status = false;
<#if USART_INTERRUPT_MODE == false>
    size_t processedSize = 0;
</#if>
    uint8_t * lBuffer = (uint8_t *)buffer;

    if(lBuffer != NULL)
    {
<#if USART_INTERRUPT_MODE == false>
        while( size > processedSize )
        {
            if(US_CSR_TXEMPTY_Msk == (USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_CSR & US_CSR_TXEMPTY_Msk))
            {
                USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_THR = (US_THR_TXCHR(*lBuffer++) & US_THR_TXCHR_Msk);
                processedSize++;
            }
        }

        status = true;
<#else>
        /* Check if transmit request is in progress */
        if(${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txBusyStatus == false)
        {
            status = true;

            ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txBuffer = lBuffer;
            ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txSize = size;
            ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txProcessedSize = 0;
            ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txBusyStatus = true;

            <#if USE_USART_TX_DMA?? && USE_USART_TX_DMA == true>
            USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_TPR = (uint32_t) buffer;
            USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_TCR = (uint32_t) size;
            USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_PTCR = US_PTCR_TXTEN_Msk;
            USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_IER = US_IER_ENDTX_Msk;
            <#else>
            /* Initiate the transfer by sending first byte */
            if(US_CSR_TXEMPTY_Msk == (USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_CSR & US_CSR_TXEMPTY_Msk))
            {
                USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_THR = (US_THR_TXCHR(*lBuffer) & US_THR_TXCHR_Msk);
                ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txProcessedSize++;
            }

            USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_IER = US_IER_TXEMPTY_Msk;
            </#if>
        }
</#if>
    }

    return status;
}

<#if USART_INTERRUPT_MODE == true>
void ${FLEXCOM_INSTANCE_NAME}_USART_WriteCallbackRegister( FLEXCOM_USART_CALLBACK callback, uintptr_t context )
{
    ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txCallback = callback;
    ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txContext = context;
}

void ${FLEXCOM_INSTANCE_NAME}_USART_ReadCallbackRegister( FLEXCOM_USART_CALLBACK callback, uintptr_t context )
{
    ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxCallback = callback;
    ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxContext = context;
}

bool ${FLEXCOM_INSTANCE_NAME}_USART_WriteIsBusy( void )
{
    return ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txBusyStatus;
}

bool ${FLEXCOM_INSTANCE_NAME}_USART_ReadIsBusy( void )
{
    return ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxBusyStatus;
}

size_t ${FLEXCOM_INSTANCE_NAME}_USART_WriteCountGet( void )
{
    <#if USE_USART_TX_DMA?? && USE_USART_TX_DMA == true>
    return (${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txSize - USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_TCR);
    <#else>
    return ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.txProcessedSize;
    </#if>
}

size_t ${FLEXCOM_INSTANCE_NAME}_USART_ReadCountGet( void )
{
    <#if USE_USART_RX_DMA?? && USE_USART_RX_DMA == true>
    return (${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxSize - USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_RCR);
    <#else>
    return ${FLEXCOM_INSTANCE_NAME?lower_case}UsartObj.rxProcessedSize;
    </#if>
}

</#if>
<#if USART_INTERRUPT_MODE == false>
uint8_t ${FLEXCOM_INSTANCE_NAME}_USART_ReadByte( void )
{
    return (USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_RHR & US_RHR_RXCHR_Msk);
}

void ${FLEXCOM_INSTANCE_NAME}_USART_WriteByte( uint8_t data )
{
    while ((US_CSR_TXEMPTY_Msk == (USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_CSR & US_CSR_TXEMPTY_Msk)) == 0);

    USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_THR = (US_THR_TXCHR(data) & US_THR_TXCHR_Msk);
}

bool ${FLEXCOM_INSTANCE_NAME}_USART_TransmitComplete( void )
{
    bool status = false;

    if(US_CSR_TXEMPTY_Msk == (USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_CSR & US_CSR_TXEMPTY_Msk))
    {
        status = true;
    }

    return status;
}

bool ${FLEXCOM_INSTANCE_NAME}_USART_TransmitterIsReady( void )
{
    bool status = false;

    if(US_CSR_TXRDY_Msk == (USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_CSR & US_CSR_TXRDY_Msk))
    {
        status = true;
    }

    return status;
}

bool ${FLEXCOM_INSTANCE_NAME}_USART_ReceiverIsReady( void )
{
    bool status = false;

    if(US_CSR_RXRDY_Msk == (USART${FLEXCOM_INSTANCE_NUMBER}_REGS->US_CSR & US_CSR_RXRDY_Msk))
    {
        status = true;
    }

    return status;
}
</#if>
