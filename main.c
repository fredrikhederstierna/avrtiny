//#define F_CPU 1000000UL

#include <avr/io.h>
#include <util/delay.h>

FUSES = {
        .low =          LFUSE_DEFAULT ,
        .high =         HFUSE_DEFAULT ,
        .extended =     EFUSE_DEFAULT ,
};

int main(void)
#if 0
{
  DDRB = 0x08;

  while (1) {
    PORTB = 0x00; _delay_ms(500);
    PORTB = 0x08; _delay_ms(500);
  }
  return 0;
}
#endif
#if 1
{
    DDRB |= _BV(DDB0); 
    
    while(1) 
    {
        PORTB ^= _BV(PB0);
        _delay_ms(500);
    }
    return 0;
}
#endif
