#include <stdint.h>

#define REG32(x) (*((volatile uint32_t *)(x)))
#define GPIO_BASE 0x40000000
#define GPIO_OUT (REG32(GPIO_BASE + 0x0))
#define GPIO_DIR (REG32(GPIO_BASE + 0x4))
#define GPIO_IN  (REG32(GPIO_BASE + 0x8))

volatile uint32_t i;

uint32_t preinit = 53;

int main(void) {
    i = 0;

    GPIO_DIR = 0xffff0000;

    while (1) {
        GPIO_OUT = i + preinit;

        i++;
        preinit++;

        /*for (int j = 0; j < 100000; j++) {
          }*/
    }
}

void irq(uint32_t a, uint32_t b) {
}
