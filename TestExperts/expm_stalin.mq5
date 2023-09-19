//+------------------------------------------------------------------+
//|                                                  ExpM_Stalin.mq5 |
//|                        Copyright 2011, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
//--- available signals
#include <Expert\Signal\StalinSignal.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingNone.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string          Expert_Title         ="ExpM_Stalin"; // Document name
ulong                 Expert_MagicNumber   =1010;          // 
bool                  Expert_EveryTick     =false;         // 
//--- inputs for main signal
input int             Signal_ThresholdOpen =40;            // Signal threshold value to open [0...100]
input int             Signal_ThresholdClose=20;            // Signal threshold value to close [0...100]
input double          Signal_PriceLevel    =0.0;           // Price level to execute a deal
input double          Signal_StopLevel     =50.0;          // Stop Loss level (in points)
input double          Signal_TakeLevel     =50.0;          // Take Profit level (in points)
input int             Signal_Expiration    =1;             // Expiration of pending orders (in bars)
input bool            Signal__BuyPosOpen   =true;          // Stalin() Permission to buy
input bool            Signal__SellPosOpen  =true;          // Stalin() Permission to sell
input bool            Signal__BuyPosClose  =true;          // Stalin() Permission to exit a long position
input bool            Signal__SellPosClose =true;          // Stalin() Permission to exit a short position
input ENUM_TIMEFRAMES Signal__Ind_Timeframe=PERIOD_H4;     // Stalin() Timeframe
input ENUM_MA_METHOD  Signal__MAMethod     =MODE_EMA;      // Stalin() Smoothing method
input uint            Signal__MAShift      =0;             // Stalin() Moving Average shift in bars
input uint            Signal__Fast         =14;            // Stalin() Fast MA period
input uint            Signal__Slow         =21;            // Stalin() Slow MA period
input uint            Signal__RSI          =17;            // Stalin() RSI period
input uint            Signal__Confirm      =0;             // Stalin() Level in points
input uint            Signal__Flat         =0;             // Stalin() Flat amplitude in points
input uint            Signal__SignalBar    =1;             // Stalin() Bar index for entry signal
input double          Signal__Weight       =1.0;           // Stalin() Weight [0...1.0]
//--- inputs for money
input double          Money_FixLot_Percent =10.0;          // Percent
input double          Money_FixLot_Lots    =0.1;           // Fixed volume
//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CExpert ExtExpert;
//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Initializing expert
   if(!ExtExpert.Init(Symbol(),Period(),Expert_EveryTick,Expert_MagicNumber))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing expert");
      ExtExpert.Deinit();
      return(-1);
     }
//--- Creating signal
   CExpertSignal *signal=new CExpertSignal;
   if(signal==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating signal");
      ExtExpert.Deinit();
      return(-2);
     }
//---
   ExtExpert.InitSignal(signal);
   signal.ThresholdOpen(Signal_ThresholdOpen);
   signal.ThresholdClose(Signal_ThresholdClose);
   signal.PriceLevel(Signal_PriceLevel);
   signal.StopLevel(Signal_StopLevel);
   signal.TakeLevel(Signal_TakeLevel);
   signal.Expiration(Signal_Expiration);
//--- Creating filter CStalinSignal
   CStalinSignal *filter0=new CStalinSignal;
   if(filter0==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter0");
      ExtExpert.Deinit();
      return(-3);
     }
   signal.AddFilter(filter0);
//--- Set filter parameters
   filter0.BuyPosOpen(Signal__BuyPosOpen);
   filter0.SellPosOpen(Signal__SellPosOpen);
   filter0.BuyPosClose(Signal__BuyPosClose);
   filter0.SellPosClose(Signal__SellPosClose);
   filter0.Ind_Timeframe(Signal__Ind_Timeframe);
   filter0.MAMethod(Signal__MAMethod);
   filter0.MAShift(Signal__MAShift);
   filter0.Fast(Signal__Fast);
   filter0.Slow(Signal__Slow);
   filter0.RSI(Signal__RSI);
   filter0.Confirm(Signal__Confirm);
   filter0.Flat(Signal__Flat);
   filter0.SignalBar(Signal__SignalBar);
   filter0.Weight(Signal__Weight);
//--- Creation of trailing object
   CTrailingNone *trailing=new CTrailingNone;
   if(trailing==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating trailing");
      ExtExpert.Deinit();
      return(-4);
     }
//--- Add trailing to expert (will be deleted automatically))
   if(!ExtExpert.InitTrailing(trailing))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing trailing");
      ExtExpert.Deinit();
      return(-5);
     }
//--- Set trailing parameters
//--- Creation of money object
   CMoneyFixedLot *money=new CMoneyFixedLot;
   if(money==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating money");
      ExtExpert.Deinit();
      return(-6);
     }
//--- Add money to expert (will be deleted automatically))
   if(!ExtExpert.InitMoney(money))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing money");
      ExtExpert.Deinit();
      return(-7);
     }
//--- Set money parameters
   money.Percent(Money_FixLot_Percent);
   money.Lots(Money_FixLot_Lots);
//--- Check all trading objects parameters
   if(!ExtExpert.ValidationSettings())
     {
      //--- failed
      ExtExpert.Deinit();
      return(-8);
     }
//--- Tuning of all necessary indicators
   if(!ExtExpert.InitIndicators())
     {
      //--- failed
      printf(__FUNCTION__+": error initializing indicators");
      ExtExpert.Deinit();
      return(-9);
     }
//--- ok
   return(0);
  }
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ExtExpert.Deinit();
  }
//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void OnTick()
  {
   ExtExpert.OnTick();
  }
//+------------------------------------------------------------------+
//| "Trade" event handler function                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
   ExtExpert.OnTrade();
  }
//+------------------------------------------------------------------+
//| "Timer" event handler function                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   ExtExpert.OnTimer();
  }
//+------------------------------------------------------------------+
