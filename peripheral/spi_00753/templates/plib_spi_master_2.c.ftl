/*******************************************************************************
  SPI PLIB

  Company:
    Microchip Technology Inc.

  File Name:
    plib_${SPI_INSTANCE_NAME?lower_case}_master.c

  Summary:
    ${SPI_INSTANCE_NAME} Master Source File

  Description:
    This file has implementation of all the interfaces provided for particular
    SPI peripheral.

*******************************************************************************/

/*******************************************************************************
* Copyright (C) 2018-2019 Microchip Technology Inc. and its subsidiaries.
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

#include "plib_${SPI_INSTANCE_NAME?lower_case}_master.h"

// *****************************************************************************
// *****************************************************************************
// Section: ${SPI_INSTANCE_NAME} Implementation
// *****************************************************************************
// *****************************************************************************

<#if SPI_INTERRUPT_MODE == true>
/* Global object to save SPI Exchange related data */
SPI_OBJECT ${SPI_INSTANCE_NAME?lower_case}Obj;
</#if>

#define ${SPI_INSTANCE_NAME}_CON_MSTEN                      (${SPI_MSTR_MODE_EN} << _${SPI_INSTANCE_NAME}CON_MSTEN_POSITION)
#define ${SPI_INSTANCE_NAME}_CON_CKP                        (${SPI_SPICON_CLK_POL} << _${SPI_INSTANCE_NAME}CON_CKP_POSITION)
#define ${SPI_INSTANCE_NAME}_CON_CKE                        (${SPI_SPICON_CLK_PH} << _${SPI_INSTANCE_NAME}CON_CKE_POSITION)
#define ${SPI_INSTANCE_NAME}_CON_MODE_32_MODE_16            (${SPI_SPICON_MODE} << _${SPI_INSTANCE_NAME}CON_MODE16_POSITION)
#define ${SPI_INSTANCE_NAME}_CON_SMP                        (${SPI_SPICON_SMP} << _${SPI_INSTANCE_NAME}CON_SMP_POSITION)

void ${SPI_INSTANCE_NAME}_Initialize ( void )
{
    uint32_t rdata;

    /* Disable ${SPI_INSTANCE_NAME} Interrupts */
    ${SPI_FLT_IEC_REG}CLR = ${SPI_FLT_IEC_REG_MASK};
    ${SPI_RX_IEC_REG}CLR = ${SPI_RX_IEC_REG_MASK};
    ${SPI_TX_IEC_REG}CLR = ${SPI_TX_IEC_REG_MASK};

    /* STOP and Reset the SPI */
    ${SPI_INSTANCE_NAME}CON = 0;

    /* Clear the Receiver buffer */
    rdata = ${SPI_INSTANCE_NAME}BUF;
    rdata = rdata;

    /* Clear ${SPI_INSTANCE_NAME} Interrupt flags */
    ${SPI_FLT_IFS_REG}CLR = ${SPI_FLT_IFS_REG_MASK};
    ${SPI_RX_IFS_REG}CLR = ${SPI_RX_IFS_REG_MASK};
    ${SPI_TX_IFS_REG}CLR = ${SPI_TX_IFS_REG_MASK};

    /* BAUD Rate register Setup */
    ${SPI_INSTANCE_NAME}BRG = ${SPI_BRG_VALUE};

    /* CLear the Overflow */
    ${SPI_INSTANCE_NAME}STATCLR = _${SPI_INSTANCE_NAME}STAT_SPIROV_MASK;

    /*
    MSTEN = ${SPI_MSTR_MODE_EN}
    CKP = ${SPI_SPICON_CLK_POL}
    CKE = ${SPI_SPICON_CLK_PH}
    MODE<32,16> = ${SPI_SPICON_MODE}
    */
    ${SPI_INSTANCE_NAME}CONSET = (${SPI_INSTANCE_NAME}_CON_MODE_32_MODE_16 | ${SPI_INSTANCE_NAME}_CON_CKE | ${SPI_INSTANCE_NAME}_CON_CKP | ${SPI_INSTANCE_NAME}_CON_MSTEN | ${SPI_INSTANCE_NAME}_CON_SMP);

<#if SPI_INTERRUPT_MODE == true>
    /* Initialize global variables */
    ${SPI_INSTANCE_NAME?lower_case}Obj.transferIsBusy = false;
    ${SPI_INSTANCE_NAME?lower_case}Obj.callback = NULL;
</#if>

    /* Enable ${SPI_INSTANCE_NAME} */
    ${SPI_INSTANCE_NAME}CONSET = _${SPI_INSTANCE_NAME}CON_ON_MASK;
}

bool ${SPI_INSTANCE_NAME}_TransferSetup (SPI_TRANSFER_SETUP* setup, uint32_t spiSourceClock )
{
<#assign spiClockSymbol = "core." + SPI_INSTANCE_NAME + "_CLOCK_FREQUENCY">
    uint32_t t_brg;
    uint32_t baudHigh;
    uint32_t baudLow;
    uint32_t errorHigh;
    uint32_t errorLow;

    if ((setup == NULL) || (setup->clockFrequency == 0))
    {
        return false;
    }

    if(spiSourceClock == 0)
    {
        // Use Master Clock Frequency set in GUI
        spiSourceClock = ${spiClockSymbol?eval};
    }

    t_brg = (((spiSourceClock / (setup->clockFrequency)) / 2u) - 1u);
    baudHigh = spiSourceClock / (2u * (t_brg + 1u));
    baudLow = spiSourceClock / (2u * (t_brg + 2u));
    errorHigh = baudHigh - setup->clockFrequency;
    errorLow = setup->clockFrequency - baudLow;

    if (errorHigh > errorLow)
    {
        t_brg++;
    }

    if(t_brg > ${SPI_MAX_BRG})
    {
        return false;
    }

    ${SPI_INSTANCE_NAME}BRG = t_brg;
    ${SPI_INSTANCE_NAME}CON = (${SPI_INSTANCE_NAME}CON & (~(_${SPI_INSTANCE_NAME}CON_MODE16_MASK | _${SPI_INSTANCE_NAME}CON_MODE32_MASK | _${SPI_INSTANCE_NAME}CON_CKP_MASK | _${SPI_INSTANCE_NAME}CON_CKE_MASK))) |
                            (setup->clockPolarity | setup->clockPhase | setup->dataBits);

    return true;
}

bool ${SPI_INSTANCE_NAME}_Write(void* pTransmitData, size_t txSize)
{
    return(${SPI_INSTANCE_NAME}_WriteRead(pTransmitData, txSize, NULL, 0));
}

bool ${SPI_INSTANCE_NAME}_Read(void* pReceiveData, size_t rxSize)
{
    return(${SPI_INSTANCE_NAME}_WriteRead(NULL, 0, pReceiveData, rxSize));
}

bool ${SPI_INSTANCE_NAME}_IsTransmitterBusy (void)
{
    return ((${SPI_INSTANCE_NAME}STAT & _${SPI_INSTANCE_NAME}STAT_SPIBUSY_MASK) != 0)? true : false;
}

<#if SPI_INTERRUPT_MODE == false>
bool ${SPI_INSTANCE_NAME}_WriteRead(void* pTransmitData, size_t txSize, void* pReceiveData, size_t rxSize)
{
    size_t txCount = 0;
    size_t rxCount = 0;
    size_t dummySize = 0;
    size_t dummyRxCntr = 0;
    size_t receivedData;

    bool isSuccess = false;

    /* Verify the request */
    if (((txSize > 0) && (pTransmitData != NULL)) || ((rxSize > 0) && (pReceiveData != NULL)))
    {
        if (pTransmitData == NULL)
        {
            txSize = 0;
        }
        if (pReceiveData == NULL)
        {
            rxSize = 0;
        }

        /* Clear the receive overflow error if any */
        ${SPI_INSTANCE_NAME}STATCLR = _${SPI_INSTANCE_NAME}STAT_SPIROV_MASK;

        /* Flush out any unread data in SPI read buffer from the previous transfer */
        while ((bool)(${SPI_INSTANCE_NAME}STAT & _${SPI_INSTANCE_NAME}STAT_SPIRBF_MASK) == true)
        {
            receivedData = ${SPI_INSTANCE_NAME}BUF;
        }

        if (rxSize > txSize)
        {
            dummySize = rxSize - txSize;
        }

        /* If dataBit size is 32 bits */
        if (_${SPI_INSTANCE_NAME}CON_MODE32_MASK == (${SPI_INSTANCE_NAME}CON & _${SPI_INSTANCE_NAME}CON_MODE32_MASK))
        {
            rxSize >>= 2;
            txSize >>= 2;
            dummySize >>= 2;
        }
        /* If dataBit size is 16 bits */
        else if (_${SPI_INSTANCE_NAME}CON_MODE16_MASK == (${SPI_INSTANCE_NAME}CON & _${SPI_INSTANCE_NAME}CON_MODE16_MASK))
        {
            rxSize >>= 1;
            txSize >>= 1;
            dummySize >>= 1;
        }

        /* Make sure transmit buffer is empty */
        while((bool)(${SPI_INSTANCE_NAME}STAT & _${SPI_INSTANCE_NAME}STAT_SPITBE_MASK) == false);

        while ((txCount != txSize) || (dummySize != 0))
        {
            if (txCount != txSize)
            {
                if((_${SPI_INSTANCE_NAME}CON_MODE32_MASK) == (${SPI_INSTANCE_NAME}CON & (_${SPI_INSTANCE_NAME}CON_MODE32_MASK)))
                {
                    ${SPI_INSTANCE_NAME}BUF = ((uint32_t*)pTransmitData)[txCount++];
                }
                else if((_${SPI_INSTANCE_NAME}CON_MODE16_MASK) == (${SPI_INSTANCE_NAME}CON & (_${SPI_INSTANCE_NAME}CON_MODE16_MASK)))
                {
                    ${SPI_INSTANCE_NAME}BUF = ((uint16_t*)pTransmitData)[txCount++];
                }
                else
                {
                    ${SPI_INSTANCE_NAME}BUF = ((uint8_t*)pTransmitData)[txCount++];
                }
            }
            else if (dummySize > 0)
            {
                ${SPI_INSTANCE_NAME}BUF = 0x${SPI_DUMMY_DATA};
                dummySize--;
            }

            if (rxCount == rxSize)
            {
                /* If inside this if condition, then it means that all RX bytes are received.
                   Now only transmit or nothing is left */

                /* For transmit only request, wait for buffer to become empty */
                while((bool)(${SPI_INSTANCE_NAME}STAT & _${SPI_INSTANCE_NAME}STAT_SPITBE_MASK) == false);

                while (dummyRxCntr != ((txCount - rxCount) - 1))
                {
                    /* Ensure the dummy receive for previous transfer in this loop.
                       We are doing for previous transfer to increase the throughput */

                    /* wait until the receive buffer is full */
                    while ((bool)(${SPI_INSTANCE_NAME}STAT & _${SPI_INSTANCE_NAME}STAT_SPIRBF_MASK) == false);

                    receivedData = ${SPI_INSTANCE_NAME}BUF;
                    dummyRxCntr++;
                }
            }
            else
            {
                /* If data is read, wait for the Receiver Data the data to become available */
                while ((bool)(${SPI_INSTANCE_NAME}STAT & _${SPI_INSTANCE_NAME}STAT_SPIRBF_MASK) == false);

                /* We have data waiting in the SPI buffer */
                receivedData = ${SPI_INSTANCE_NAME}BUF;

                if (rxCount < rxSize)
                {
                    if((_${SPI_INSTANCE_NAME}CON_MODE32_MASK) == (${SPI_INSTANCE_NAME}CON & (_${SPI_INSTANCE_NAME}CON_MODE32_MASK)))
                    {
                        ((uint32_t*)pReceiveData)[rxCount++]  = receivedData;
                    }
                    else if((_${SPI_INSTANCE_NAME}CON_MODE16_MASK) == (${SPI_INSTANCE_NAME}CON & (_${SPI_INSTANCE_NAME}CON_MODE16_MASK)))
                    {
                        ((uint16_t*)pReceiveData)[rxCount++]  = receivedData;
                    }
                    else
                    {
                        ((uint8_t*)pReceiveData)[rxCount++]  = receivedData;
                    }
                }
            }
        }

        /* Make sure for every character transmitted a character is also received back.
         * If this is not done, we may prematurely exit this routine with the last bit still being
         * transmitted out. As a result, the application may prematurely deselect the CS line and also
         * the next request can receive last character of previous request as its first character.
         */
        if (txSize > rxSize)
        {
            while (dummyRxCntr != (txCount - rxCount))
            {
                /* wait until the receive buffer is full */
                while ((bool)(${SPI_INSTANCE_NAME}STAT & _${SPI_INSTANCE_NAME}STAT_SPIRBF_MASK) == false);

                receivedData = ${SPI_INSTANCE_NAME}BUF;
                dummyRxCntr++;
            }
        }
        isSuccess = true;
    }

    return isSuccess;
}
<#else>
bool ${SPI_INSTANCE_NAME}_WriteRead (void* pTransmitData, size_t txSize, void* pReceiveData, size_t rxSize)
{
    bool isRequestAccepted = false;
    uint32_t dummyData;

    /* Verify the request */
    if((${SPI_INSTANCE_NAME?lower_case}Obj.transferIsBusy == false) && (((txSize > 0) && (pTransmitData != NULL)) || ((rxSize > 0) && (pReceiveData != NULL))))
    {
        isRequestAccepted = true;
        ${SPI_INSTANCE_NAME?lower_case}Obj.txBuffer = pTransmitData;
        ${SPI_INSTANCE_NAME?lower_case}Obj.rxBuffer = pReceiveData;
        ${SPI_INSTANCE_NAME?lower_case}Obj.rxCount = 0;
        ${SPI_INSTANCE_NAME?lower_case}Obj.txCount = 0;
        ${SPI_INSTANCE_NAME?lower_case}Obj.dummySize = 0;

        if (pTransmitData != NULL)
        {
            ${SPI_INSTANCE_NAME?lower_case}Obj.txSize = txSize;
        }
        else
        {
            ${SPI_INSTANCE_NAME?lower_case}Obj.txSize = 0;
        }

        if (pReceiveData != NULL)
        {
            ${SPI_INSTANCE_NAME?lower_case}Obj.rxSize = rxSize;
        }
        else
        {
            ${SPI_INSTANCE_NAME?lower_case}Obj.rxSize = 0;
        }

        ${SPI_INSTANCE_NAME?lower_case}Obj.transferIsBusy = true;

        if (${SPI_INSTANCE_NAME?lower_case}Obj.rxSize > ${SPI_INSTANCE_NAME?lower_case}Obj.txSize)
        {
            ${SPI_INSTANCE_NAME?lower_case}Obj.dummySize = ${SPI_INSTANCE_NAME?lower_case}Obj.rxSize - ${SPI_INSTANCE_NAME?lower_case}Obj.txSize;
        }

        /* Clear the receive overflow error if any */
        ${SPI_INSTANCE_NAME}STATCLR = _${SPI_INSTANCE_NAME}STAT_SPIROV_MASK;

        /* Make sure there is no data pending in the RX buffer */
        while ((bool)(${SPI_INSTANCE_NAME}STAT & _${SPI_INSTANCE_NAME}STAT_SPIRBF_MASK) == true)
        {
            dummyData = ${SPI_INSTANCE_NAME}BUF;
            (void)dummyData;
        }

        /* Disable the receive interrupt */
        ${SPI_RX_IEC_REG}CLR = ${SPI_RX_IEC_REG_MASK};

        /* Disable the transmit interrupt */
        ${SPI_TX_IEC_REG}CLR = ${SPI_TX_IEC_REG_MASK};

        /* Clear the receive interrupt flag */
        ${SPI_RX_IFS_REG}CLR = ${SPI_RX_IFS_REG_MASK};

        /* Clear the transmit interrupt flag */
        ${SPI_TX_IFS_REG}CLR = ${SPI_TX_IFS_REG_MASK};

        /* Start the first write here itself, rest will happen in ISR context */
        if((_${SPI_INSTANCE_NAME}CON_MODE32_MASK) == (${SPI_INSTANCE_NAME}CON & (_${SPI_INSTANCE_NAME}CON_MODE32_MASK)))
        {
            ${SPI_INSTANCE_NAME?lower_case}Obj.txSize >>= 2;
            ${SPI_INSTANCE_NAME?lower_case}Obj.dummySize >>= 2;
            ${SPI_INSTANCE_NAME?lower_case}Obj.rxSize >>= 2;

            if(${SPI_INSTANCE_NAME?lower_case}Obj.txCount < ${SPI_INSTANCE_NAME?lower_case}Obj.txSize)
            {
                ${SPI_INSTANCE_NAME}BUF = *((uint32_t*)${SPI_INSTANCE_NAME?lower_case}Obj.txBuffer);
                ${SPI_INSTANCE_NAME?lower_case}Obj.txCount++;
            }
            else if (${SPI_INSTANCE_NAME?lower_case}Obj.dummySize > 0)
            {
                ${SPI_INSTANCE_NAME}BUF = (uint32_t)(0x${SPI_DUMMY_DATA});
                ${SPI_INSTANCE_NAME?lower_case}Obj.dummySize--;
            }
        }
        else if((_${SPI_INSTANCE_NAME}CON_MODE16_MASK) == (${SPI_INSTANCE_NAME}CON & (_${SPI_INSTANCE_NAME}CON_MODE16_MASK)))
        {
            ${SPI_INSTANCE_NAME?lower_case}Obj.txSize >>= 1;
            ${SPI_INSTANCE_NAME?lower_case}Obj.dummySize >>= 1;
            ${SPI_INSTANCE_NAME?lower_case}Obj.rxSize >>= 1;

            if (${SPI_INSTANCE_NAME?lower_case}Obj.txCount < ${SPI_INSTANCE_NAME?lower_case}Obj.txSize)
            {
                ${SPI_INSTANCE_NAME}BUF = *((uint16_t*)${SPI_INSTANCE_NAME?lower_case}Obj.txBuffer);
                ${SPI_INSTANCE_NAME?lower_case}Obj.txCount++;
            }
            else if (${SPI_INSTANCE_NAME?lower_case}Obj.dummySize > 0)
            {
                ${SPI_INSTANCE_NAME}BUF = (uint16_t)(0x${SPI_DUMMY_DATA});
                ${SPI_INSTANCE_NAME?lower_case}Obj.dummySize--;
            }
        }
        else
        {
            if (${SPI_INSTANCE_NAME?lower_case}Obj.txCount < ${SPI_INSTANCE_NAME?lower_case}Obj.txSize)
            {
                ${SPI_INSTANCE_NAME}BUF = *((uint8_t*)${SPI_INSTANCE_NAME?lower_case}Obj.txBuffer);
                ${SPI_INSTANCE_NAME?lower_case}Obj.txCount++;
            }
            else if (${SPI_INSTANCE_NAME?lower_case}Obj.dummySize > 0)
            {
                ${SPI_INSTANCE_NAME}BUF = (uint8_t)(0x${SPI_DUMMY_DATA});
                ${SPI_INSTANCE_NAME?lower_case}Obj.dummySize--;
            }
        }

        /* Enable receive interrupt to complete the transfer in ISR context.
            * Keep the transmit interrupt disabled. */
        ${SPI_RX_IEC_REG}SET = ${SPI_RX_IEC_REG_MASK};
    }

    return isRequestAccepted;
}

bool ${SPI_INSTANCE_NAME}_IsBusy (void)
{
    return ( (${SPI_INSTANCE_NAME?lower_case}Obj.transferIsBusy) || ((${SPI_INSTANCE_NAME}STAT & _${SPI_INSTANCE_NAME}STAT_SPIBUSY_MASK) != 0));
}

void ${SPI_INSTANCE_NAME}_CallbackRegister (SPI_CALLBACK callback, uintptr_t context)
{
    ${SPI_INSTANCE_NAME?lower_case}Obj.callback = callback;

    ${SPI_INSTANCE_NAME?lower_case}Obj.context = context;
}

<#if SPI_INTERRUPT_COUNT == 1>
static void __attribute__((used)) ${SPI_INSTANCE_NAME}_RX_InterruptHandler (void)
<#else>
void __attribute__((used)) ${SPI_INSTANCE_NAME}_RX_InterruptHandler (void)
</#if>
{
    uint32_t receivedData = 0;

    /* Check if the receive buffer is full or not */
    if ((bool)(${SPI_INSTANCE_NAME}STAT & _${SPI_INSTANCE_NAME}STAT_SPIRBF_MASK) == true)
    {
        /* Receive buffer is full. Read the received data. */
        receivedData = ${SPI_INSTANCE_NAME}BUF;

        if (${SPI_INSTANCE_NAME?lower_case}Obj.rxCount < ${SPI_INSTANCE_NAME?lower_case}Obj.rxSize)
        {
            /* Copy the received data to the user buffer */
            if((_${SPI_INSTANCE_NAME}CON_MODE32_MASK) == (${SPI_INSTANCE_NAME}CON & (_${SPI_INSTANCE_NAME}CON_MODE32_MASK)))
            {
                ((uint32_t*)${SPI_INSTANCE_NAME?lower_case}Obj.rxBuffer)[${SPI_INSTANCE_NAME?lower_case}Obj.rxCount++] = receivedData;
            }
            else if((_${SPI_INSTANCE_NAME}CON_MODE16_MASK) == (${SPI_INSTANCE_NAME}CON & (_${SPI_INSTANCE_NAME}CON_MODE16_MASK)))
            {
                ((uint16_t*)${SPI_INSTANCE_NAME?lower_case}Obj.rxBuffer)[${SPI_INSTANCE_NAME?lower_case}Obj.rxCount++] = receivedData;
            }
            else
            {
                ((uint8_t*)${SPI_INSTANCE_NAME?lower_case}Obj.rxBuffer)[${SPI_INSTANCE_NAME?lower_case}Obj.rxCount++] = receivedData;
            }
        }
        if ((${SPI_INSTANCE_NAME?lower_case}Obj.rxCount < ${SPI_INSTANCE_NAME?lower_case}Obj.rxSize) || (${SPI_INSTANCE_NAME?lower_case}Obj.txCount < ${SPI_INSTANCE_NAME?lower_case}Obj.txSize))
        {
            /* transmit the data here */
            if((_${SPI_INSTANCE_NAME}CON_MODE32_MASK) == (${SPI_INSTANCE_NAME}CON & (_${SPI_INSTANCE_NAME}CON_MODE32_MASK)))
            {
                if (${SPI_INSTANCE_NAME?lower_case}Obj.txCount < ${SPI_INSTANCE_NAME?lower_case}Obj.txSize)
                {
                    ${SPI_INSTANCE_NAME}BUF = ((uint32_t*)${SPI_INSTANCE_NAME?lower_case}Obj.txBuffer)[${SPI_INSTANCE_NAME?lower_case}Obj.txCount++];
                }
                else if (${SPI_INSTANCE_NAME?lower_case}Obj.dummySize > 0)
                {
                    ${SPI_INSTANCE_NAME}BUF = (uint32_t)(0x${SPI_DUMMY_DATA});
                    ${SPI_INSTANCE_NAME?lower_case}Obj.dummySize--;
                }
            }
            else if((_${SPI_INSTANCE_NAME}CON_MODE16_MASK) == (${SPI_INSTANCE_NAME}CON & (_${SPI_INSTANCE_NAME}CON_MODE16_MASK)))
            {
                if (${SPI_INSTANCE_NAME?lower_case}Obj.txCount < ${SPI_INSTANCE_NAME?lower_case}Obj.txSize)
                {
                    ${SPI_INSTANCE_NAME}BUF = ((uint16_t*)${SPI_INSTANCE_NAME?lower_case}Obj.txBuffer)[${SPI_INSTANCE_NAME?lower_case}Obj.txCount++];
                }
                else if (${SPI_INSTANCE_NAME?lower_case}Obj.dummySize > 0)
                {
                    ${SPI_INSTANCE_NAME}BUF = (uint16_t)(0x${SPI_DUMMY_DATA});
                    ${SPI_INSTANCE_NAME?lower_case}Obj.dummySize--;
                }
            }
            else
            {
                if (${SPI_INSTANCE_NAME?lower_case}Obj.txCount < ${SPI_INSTANCE_NAME?lower_case}Obj.txSize)
                {
                    ${SPI_INSTANCE_NAME}BUF = ((uint8_t*)${SPI_INSTANCE_NAME?lower_case}Obj.txBuffer)[${SPI_INSTANCE_NAME?lower_case}Obj.txCount++];
                }
                else if (${SPI_INSTANCE_NAME?lower_case}Obj.dummySize > 0)
                {
                    ${SPI_INSTANCE_NAME}BUF = (uint8_t)(0x${SPI_DUMMY_DATA});
                    ${SPI_INSTANCE_NAME?lower_case}Obj.dummySize--;
                }
            }
        }
        else
        {
            if((${SPI_INSTANCE_NAME?lower_case}Obj.rxCount == ${SPI_INSTANCE_NAME?lower_case}Obj.rxSize) && (${SPI_INSTANCE_NAME?lower_case}Obj.txCount == ${SPI_INSTANCE_NAME?lower_case}Obj.txSize))
            {
                /* Clear receiver overflow error if any */
                ${SPI_INSTANCE_NAME}STATCLR = _${SPI_INSTANCE_NAME}STAT_SPIROV_MASK;

                /* Disable receive interrupt */
                ${SPI_RX_IEC_REG}CLR = ${SPI_RX_IEC_REG_MASK};

                /* Transfer complete. Give a callback */
                ${SPI_INSTANCE_NAME?lower_case}Obj.transferIsBusy = false;

                if(${SPI_INSTANCE_NAME?lower_case}Obj.callback != NULL)
                {
                    ${SPI_INSTANCE_NAME?lower_case}Obj.callback(${SPI_INSTANCE_NAME?lower_case}Obj.context);
                }
            }
        }
    }

    /* Clear ${SPI_INSTANCE_NAME} RX Interrupt flag */
    /* This flag should cleared only after reading buffer */
    ${SPI_RX_IFS_REG}CLR = ${SPI_RX_IFS_REG_MASK};
}

<#if SPI_INTERRUPT_COUNT == 1>
void __attribute__((used)) SPI_${SPI_INSTANCE_NUM}_InterruptHandler (void)
{
    if ((${SPI_RX_IFS_REG} & _${SPI_RX_IFS_REG}_${SPI_INSTANCE_NAME}RXIF_MASK) && (${SPI_RX_IEC_REG} & _${SPI_RX_IEC_REG}_${SPI_INSTANCE_NAME}RXIE_MASK))
    {
        /* RX interrupt is enabled and RX buffer is not empty */
        ${SPI_INSTANCE_NAME}_RX_InterruptHandler();
    }
}
</#if>
</#if>