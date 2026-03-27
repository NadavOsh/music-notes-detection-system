#include "xil_printf.h"
#include "xil_io.h"
#include <unistd.h>  // For usleep()

#define BASE_ADDR_0x4000_0000 0x40000000  // Trigger write
#define BASE_ADDR_0x4000_0008 0x40000008  // Increment value
#define BASE_ADDR_0x4001_0000 0x40010000  // Read data
#define BASE_ADDR_0x4002_0000 0x40020000  // LED control
#define BASE_ADDR_0x4002_0008 0x40020008  // Bit 0 status
#define BASE_ADDR_0x4003_0000 0x40030000  // Repeat trigger

#define BIT_MASK 0x1
#define WIDTH 640

int main() {
    uint32_t increment_value = 0x0;

    const int x_start = 170;
    const int x_end = 340;
    const int y_start = 140;
    const int y_end = 340;

    while (1) {
        //xil_printf("Processing started...\n\r");

        *((volatile uint32_t *)BASE_ADDR_0x4002_0000) = 0x1;

        while ((*((volatile uint32_t *)BASE_ADDR_0x4002_0008) & BIT_MASK) == 0) {
            usleep(100);
        }

        *((volatile uint32_t *)BASE_ADDR_0x4002_0000) = 0x3;

        for (int y = y_start; y < y_end; y++) {
            for (int x = x_start; x < x_end; x++) {
                increment_value = y * WIDTH + x;

                usleep(100);
                *((volatile uint32_t *)BASE_ADDR_0x4000_0000) = 0x1;
                *((volatile uint32_t *)BASE_ADDR_0x4000_0008) = increment_value;

                uint32_t read_data = *((volatile uint32_t *)BASE_ADDR_0x4001_0000);
                usleep(100);

                xil_printf("0x%08X %d\n\r", read_data, increment_value);

                usleep(100);
                *((volatile uint32_t *)BASE_ADDR_0x4000_0000) = 0x0;
                usleep(100);
            }
        }

        *((volatile uint32_t *)BASE_ADDR_0x4002_0000) = 0x7;
        //xil_printf("\nProcessing finished.\n");

        // Wait until 0x40030000 becomes 1
        //xil_printf("Waiting to restart...\n\r");
        while ((*((volatile uint32_t *)BASE_ADDR_0x4003_0000) & 0x1) == 0) {
            usleep(100);
        }

        //xil_printf("Restart triggered!\n\r");
        // Then the loop starts again from the top
    }

    return 0;
}
