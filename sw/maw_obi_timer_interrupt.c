#include <stdint.h>

#include "util.h"
#include "uart.h"
#include "print.h"
#include "config.h"


#define ADDR_TIMER 0x0300A000
#define ADDR_TIMER_COUNT_OFFSET 0x0
#define ADDR_TIMER_COMPARE_OFFSET 0x04
#define ADDR_TIMER_CTRL_OFFSET 0x08
#define ADDR_TIMER_STATUS_OFFSET 0x0C

static volatile uint32_t irq_cause = 0;
volatile int wait_for_timer;

__attribute__((interrupt("machine")))
void direct_handler(void) {
  uint32_t cause = get_mcause() & 0x7FFFFFFF; // strip MSB to get interrupt ID
  irq_cause = cause;
  if (cause == IRQ_OBI_TIMER) {
    *reg32(ADDR_TIMER, ADDR_TIMER_STATUS_OFFSET) = 0x1;
    *reg32(ADDR_TIMER, ADDR_TIMER_CTRL_OFFSET) = 0;
    wait_for_timer = 0;
  }
  // mret is generated automatically by the interrupt attribute
}

int main() {
  // Point mtvec directly at our handler, bypassing the bootrom trap wrapper
  asm volatile("csrw mtvec, %0" :: "r"(direct_handler) : "memory");

  set_interrupt_enable(1, IRQ_OBI_TIMER);
  set_global_irq_enable(1);

  uart_init();
  
  printf("WAIT FOR TIMER\n");
  wait_for_timer = 1;
  
  //RESET THE TIMER
  *reg32(ADDR_TIMER, ADDR_TIMER_COUNT_OFFSET) = 0x0A;
  *reg32(ADDR_TIMER, ADDR_TIMER_COMPARE_OFFSET) = 0x2A;
  *reg32(ADDR_TIMER, ADDR_TIMER_CTRL_OFFSET) = 0b11; // AUTORESET/ENABLE

  while(wait_for_timer);
  wait_for_timer = 1;

  printf("ENDED COUNTER\n");

  uart_write_flush();    
  return 0;
}

