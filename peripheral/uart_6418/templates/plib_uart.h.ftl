/*******************************************************************************
  UART${INDEX?string} PLIB

  Company:
    Microchip Technology Inc.

  File Name:
    plib_uart${INDEX?string}.h

  Summary:
    UART${INDEX?string} PLIB Header File

  Description:
    None

*******************************************************************************/

/*******************************************************************************
Copyright (c) 2017 released Microchip Technology Inc.  All rights reserved.

Microchip licenses to you the right to use, modify, copy and distribute
Software only when embedded on a Microchip microcontroller or digital signal
controller that is integrated into your product or third party product
(pursuant to the sublicense terms in the accompanying license agreement).

You should refer to the license agreement accompanying this Software for
additional information regarding your rights and obligations.

SOFTWARE AND DOCUMENTATION ARE PROVIDED AS IS  WITHOUT  WARRANTY  OF  ANY  KIND,
EITHER EXPRESS  OR  IMPLIED,  INCLUDING  WITHOUT  LIMITATION,  ANY  WARRANTY  OF
MERCHANTABILITY, TITLE, NON-INFRINGEMENT AND FITNESS FOR A  PARTICULAR  PURPOSE.
IN NO EVENT SHALL MICROCHIP OR  ITS  LICENSORS  BE  LIABLE  OR  OBLIGATED  UNDER
CONTRACT, NEGLIGENCE, STRICT LIABILITY, CONTRIBUTION,  BREACH  OF  WARRANTY,  OR
OTHER LEGAL  EQUITABLE  THEORY  ANY  DIRECT  OR  INDIRECT  DAMAGES  OR  EXPENSES
INCLUDING BUT NOT LIMITED TO ANY  INCIDENTAL,  SPECIAL,  INDIRECT,  PUNITIVE  OR
CONSEQUENTIAL DAMAGES, LOST  PROFITS  OR  LOST  DATA,  COST  OF  PROCUREMENT  OF
SUBSTITUTE  GOODS,  TECHNOLOGY,  SERVICES,  OR  ANY  CLAIMS  BY  THIRD   PARTIES
(INCLUDING BUT NOT LIMITED TO ANY DEFENSE  THEREOF),  OR  OTHER  SIMILAR  COSTS.
*******************************************************************************/

#ifndef PLIB_UART${INDEX?string}_H
#define PLIB_UART${INDEX?string}_H

#include "plib_uart.h"

// DOM-IGNORE-BEGIN
#ifdef __cplusplus  // Provide C++ Compatibility

    extern "C" {

#endif
// DOM-IGNORE-END

<#--Interface To Use-->
// *****************************************************************************
// *****************************************************************************
// Section: Interface
// *****************************************************************************
// *****************************************************************************

/****************************** UART${INDEX?string} API *********************************/
void UART${INDEX?string}_Initialize( void );

UART_ERROR UART${INDEX?string}_ErrorGet( void );

int32_t UART${INDEX?string}_Read( void *buffer, const size_t size );

int32_t UART${INDEX?string}_Write( void *buffer, const size_t size );

<#if INTERRUPT_MODE == true>
void UART${INDEX?string}_CallbackRegister( UART_CALLBACK callback, uintptr_t context );

UART_TRANSFER_STATUS UART${INDEX?string}_TransferStatusGet( UART_DIRECTION direction );

size_t UART${INDEX?string}_TransferCountGet( UART_DIRECTION direction );


// *****************************************************************************
// *****************************************************************************
// Section: Local: **** Do Not Use ****
// *****************************************************************************
// *****************************************************************************

/***************************** UART${INDEX?string} Inline *******************************/

extern UART_OBJECT uart${INDEX?string}Obj;

void inline UART${INDEX?string}_ISR_ERR_Handler( void )
{
    uint8_t dummyData = 0u;

    uart${INDEX?string}Obj.error = (_UART${INDEX?string}_REGS->UART_SR.w & (UART_SR_OVRE_Msk | UART_SR_FRAME_Msk | UART_SR_PARE_Msk));
   
    if(uart${INDEX?string}Obj.error != UART_ERROR_NONE)
    {   
         /* Clear all error flags */
        _UART${INDEX?string}_REGS->UART_CR.w |= UART_CR_RSTSTA_Msk;

        /* Flush existing error bytes from the RX FIFO */
        while( UART_SR_RXRDY_Msk == (_UART${INDEX?string}_REGS->UART_SR.w & UART_SR_RXRDY_Msk) )
        {
            dummyData = (_UART${INDEX?string}_REGS->UART_RHR.w & UART_RHR_RXCHR_Msk);
        }
        
        /* Ignore the warning */
        (void)dummyData;
        
        uart${INDEX?string}Obj.rxStatus = UART_TRANSFER_ERROR;

        if( uart${INDEX?string}Obj.callback != NULL )
        {            
            uart${INDEX?string}Obj.callback(UART_TRANSFER_ERROR, UART_DIRECTION_RX, uart${INDEX?string}Obj.context);
        }
    }
}

void inline UART${INDEX?string}_ISR_RX_Handler( void )
{
    if(uart${INDEX?string}Obj.rxStatus == UART_TRANSFER_PROCESSING)
    {
        while((UART_SR_RXRDY_Msk == (_UART${INDEX?string}_REGS->UART_SR.w & UART_SR_RXRDY_Msk)) && (uart${INDEX?string}Obj.rxSize > uart${INDEX?string}Obj.rxProcessedSize) )
        {
            uart${INDEX?string}Obj.rxBuffer[uart${INDEX?string}Obj.rxProcessedSize++] = (_UART${INDEX?string}_REGS->UART_RHR.w & UART_RHR_RXCHR_Msk);
        }

        /* Check if the buffer is done */
        if(uart${INDEX?string}Obj.rxProcessedSize >= uart${INDEX?string}Obj.rxSize)
        {
            uart${INDEX?string}Obj.rxStatus = UART_TRANSFER_COMPLETE;
            uart${INDEX?string}Obj.rxSize = 0;
            uart${INDEX?string}Obj.rxProcessedSize = 0;
            _UART${INDEX?string}_REGS->UART_IDR.w |= UART_IDR_RXRDY_Msk;

            if(uart${INDEX?string}Obj.callback != NULL)
            {
                uart${INDEX?string}Obj.callback(UART_TRANSFER_COMPLETE, UART_DIRECTION_RX, uart${INDEX?string}Obj.context);
            }
        }
    }
    else
    {
        /* Nothing to process */
        ;
    }
}

void inline UART${INDEX?string}_ISR_TX_Handler( void )
{
    if(uart${INDEX?string}Obj.txStatus == UART_TRANSFER_PROCESSING)
    {
        while((UART_SR_TXEMPTY_Msk == (_UART${INDEX?string}_REGS->UART_SR.w & UART_SR_TXEMPTY_Msk)) && (uart${INDEX?string}Obj.txSize > uart${INDEX?string}Obj.txProcessedSize) )
        {
            _UART${INDEX?string}_REGS->UART_THR.w |= uart${INDEX?string}Obj.txBuffer[uart${INDEX?string}Obj.txProcessedSize++];
        }

        /* Check if the buffer is done */
        if(uart${INDEX?string}Obj.txProcessedSize >= uart${INDEX?string}Obj.txSize)
        {
            uart${INDEX?string}Obj.txStatus = UART_TRANSFER_COMPLETE;
            uart${INDEX?string}Obj.txSize = 0;
            uart${INDEX?string}Obj.txProcessedSize = 0;
            _UART${INDEX?string}_REGS->UART_IDR.w |= UART_IDR_TXEMPTY_Msk;
            
            if(uart${INDEX?string}Obj.callback != NULL)
            {
                uart${INDEX?string}Obj.callback(UART_TRANSFER_COMPLETE, UART_DIRECTION_TX, uart${INDEX?string}Obj.context);
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

// DOM-IGNORE-BEGIN
#ifdef __cplusplus  // Provide C++ Compatibility

    }

#endif
// DOM-IGNORE-END
#endif // PLIB_UART${INDEX?string}_H
