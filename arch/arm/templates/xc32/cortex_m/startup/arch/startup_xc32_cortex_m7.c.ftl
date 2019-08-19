<#if TCM_ENABLE>
__STATIC_INLINE void TCM_Enable(void);
<#else>
__STATIC_INLINE void TCM_Disable(void);
</#if>
<#if !(TCM_FIXED_SIZE??)>
__STATIC_INLINE void TCM_Configure(uint32_t tcmSize);
</#if>
__STATIC_INLINE void ICache_Enable(void);
__STATIC_INLINE void DCache_Enable(void);
__STATIC_INLINE void FPU_Enable(void);

/* Enable Instruction Cache */
__STATIC_INLINE void ICache_Enable(void)
{
    SCB_EnableICache();
}

/* Enable Data Cache */
__STATIC_INLINE void DCache_Enable(void)
{
    SCB_EnableDCache();
}

#if (__ARM_FP==14) || (__ARM_FP==4)

/* Enable FPU */
__STATIC_INLINE void FPU_Enable(void)
{
uint32_t prim;
    prim = __get_PRIMASK();
    __disable_irq();

     SCB->CPACR |= (0xFu << 20);
    __DSB();
    __ISB();

    if (!prim)
    {
        __enable_irq();
    }
}
#endif /* (__ARM_FP==14) || (__ARM_FP==4) */

<#if TCM_ECC_ENABLE>
__STATIC_INLINE void FPU_MemToFpu(unsigned int address)
{
    asm volatile (
         "MOV      r8, %[addr]\n"
         "PLD      [r8, #0xC0]\n"
         "VLDM     r8!,{d0-d15}\n"
           : : [addr] "l" (address) : "r8"
    );
}

__STATIC_INLINE void FPU_FpuToMem(unsigned int address)
{
    asm volatile (
         "MOV      r8, %[addr]\n"
         "VSTM     r8!,{d0-d15}\n"
           : : [addr] "l" (address) : "r8"
    );
}
</#if>

