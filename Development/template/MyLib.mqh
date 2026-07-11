#ifndef MYLIB_MQH
#define MYLIB_MQH

double PipsToPrice(double pips, string symbol)
{
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   return pips * tickSize * 10;
}

#endif
