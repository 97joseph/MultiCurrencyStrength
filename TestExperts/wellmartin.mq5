//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                  Well Martin.mq5 |
//|                                              Copyright 2015, AM2 |
//|                                      http://www.forexsystems.biz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, AM2"
#property link      "http://www.forexsystems.biz"
#property version   "1.00"
//---

#include <Trade\OrderInfo.mqh>
//--- object for conducting trading operations
COrderInfo myorder;
//input parameters
input bool Autostop = false;
input ENUM_TIMEFRAMES AutostopTime = PERIOD_CURRENT;
input int  AutostopPeriod = 3;
input ENUM_SERIESMODE AutostopBuyMode = MODE_CLOSE;
input ENUM_SERIESMODE AutostopSellMode = MODE_CLOSE;
input bool AutoTP = false;
input ENUM_TIMEFRAMES AutoTPTime = PERIOD_CURRENT;
input int  AutoTPPeriod = 3;
input ENUM_SERIESMODE AutoTPBuyMode = MODE_CLOSE;
input ENUM_SERIESMODE AutoTPSellMode = MODE_CLOSE;

input bool PSARstop = false;
input ENUM_TIMEFRAMES base_tf;  //set timeframe
input double sar_step=0.1;      //set parabolic step
input double maximum_step=0.11; //set parabolic maximum step
int Sar_base;

#include <Trade\Trade.mqh>            // ?????????? ???????? ????? CTrade
//--- ??????? ????????? ?????????? Bollinger Bands
input int      BBPeriod  = 84;
input int      BBShift   = 0;
input double   BBDev     = 1.8;
input ENUM_TIMEFRAMES BBtimeframe = PERIOD_CURRENT;
//--- ??????? ????????? ?????????? ADX
input ENUM_TIMEFRAMES ADXtimeframe = PERIOD_CURRENT;

input int      ADXPeriod = 40;
input int      ADXLevel  = 45;
//--- ??????? ????????? ????????
int      TP        = 1200;
int      SL        = 6000;
input int      Slip      = 50;
input int      Stelth    = 0;
input double   KLot      = 2;
input double   MaxLot    = 5;
input double   Lot       = 0.1;
input color    LableClr  = clrGreen;
//--- ?????????? ??????????
int BBHandle;                         // ????? ?????????? Bolinger Bands
int ADXHandle;                        // ????? ?????????? ADX
double BBUp[],BBLow[];                // ???????????? ??????? ??? ???????? ????????? ???????? Bollinger Bands
double ADX[];                         // ???????????? ??????? ??? ???????? ????????? ???????? ADX
CTrade trade;                         // ?????????? ???????? ????? CTrade
bool Buy ;
bool Sell;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- ???????? ????? ???????????  Bollinger Bands ? ADX
   BBHandle=iBands(_Symbol,BBtimeframe,BBPeriod,BBShift,BBDev,PRICE_CLOSE);
   ADXHandle=iADX(_Symbol,ADXtimeframe,ADXPeriod);

//--- ????? ?????????, ?? ???? ?? ?????????? ???????? Invalid Handle
   if(BBHandle==INVALID_HANDLE || ADXHandle==INVALID_HANDLE)
     {
      Print(" ?? ??????? ???????? ????? ???????????");
      return(INIT_FAILED);
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

//--- ??????????? ?????? ???????????
   IndicatorRelease(BBHandle);
   IndicatorRelease(ADXHandle);
//--- ?????? ????????? ?????
   ObjectsDeleteAll(0,0,OBJ_ARROW_LEFT_PRICE);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(Symbol(),Period(),0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
   if(!RefreshRates(Symbol()))
     {
      PrevBars=0;
      return;
     }
//SAROnTick();
   Buy = false;
   Sell = false;
//--- ????? ????????? ????, ?????? ? ????? ??? ??????? ????
//--- ????????? ?????????? ? ???????? ????????? ? ???????????  ??? ? ??????????
//--- ?????? ?????????
//--- ?????? ???????? ???????????
   ArraySetAsSeries(BBUp,true);
   ArraySetAsSeries(BBLow,true);
   ArraySetAsSeries(ADX,true);
//--- ??????? ???????????? ?????? ????????? 3-? ?????
//--- ???????? ???????? ?????????? Bolinger Bands ????????? ??????
   if(CopyBuffer(BBHandle,1,0,3,BBUp)<0 || CopyBuffer(BBHandle,2,0,3,BBLow)<0)
     {
      Alert("?????? ??????????? ??????? ?????????? Bollinger Bands - ????? ??????:",GetLastError(),"!");
      return;
     }
//--- ???????? ???????? ?????????? ADX ????????? ??????
   if(CopyBuffer(ADXHandle,0,0,3,ADX)<0)
     {
      Alert("?????? ??????????? ??????? ?????????? ADX - ????? ??????:",GetLastError(),"!");
      return;
     }
//--- ?????? ??????????? ?? ???????
   double Ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
//--- ?????? ??????????? ?? ???????
   double Bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
//--- ??????
   double pr=0;
//--- ?????
   double stop=0,take=0;
//--- ????????? ?????????? ???? boolean, ??? ????? ?????????????? ??? ???????? ??????? ??? ??????? ? ???????
//--- ?????? ??????? ??????? Bolinger Bands ? ??????????????? ??????

   Buy=Ask<BBLow[1] && ADX[1]<ADXLevel && (LastDealType()==0 || LastDealType()==2);
   Sell=Bid>BBUp[1] && ADX[1]<ADXLevel && (LastDealType()==0 || LastDealType()==1);




//--- ???????? ?? ????? ???
   if(IsNewBar(_Symbol,BBtimeframe))
     {
      //--- ??? ??????? ? ?????? ?? ???????
      if(PositionsTotal()<1 && Buy)
        {
         //--- ????????? ?????
         if(SL==0)
            stop=0;
         else
            stop=NormalizeDouble(Ask-SL*_Point,_Digits);
         if(TP==0)
            take=0;
         else
            take=NormalizeDouble(Ask+TP*_Point,_Digits);
         //--- ????? ???????????
         if(Stelth==1)
           {
            stop=0;
            take=0;
           }
         //--- ????????? ????? ?? ???????
         if(Autostop)//stopbuy
           {
            stop=NormalizeDouble(iLow(Symbol(),AutostopTime,iLowest(NULL,AutostopTime,AutostopBuyMode,AutostopPeriod,0)),_Digits);
            if(stop>NormalizeDouble(Ask-SL*_Point,_Digits))
              {
               stop=NormalizeDouble(iLow(Symbol(),AutostopTime,iLowest(NULL,AutostopTime,AutostopBuyMode,AutostopPeriod,0)),_Digits)-40.00;
              }
           }
         if(AutoTP)//AutoTPbuy
           {
            take=NormalizeDouble(iHigh(Symbol(),AutoTPTime,iHighest(NULL,AutoTPTime,AutoTPBuyMode,AutoTPPeriod,0)),_Digits);
            if(take<NormalizeDouble(Ask+TP*_Point,_Digits))
              {
               stop=NormalizeDouble(iHigh(Symbol(),AutoTPTime,iHighest(NULL,AutoTPTime,AutoTPBuyMode,AutoTPPeriod,0)),_Digits)+40.00;
              }
           }
         trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,Volume(),Ask,stop,take);
         //--- ?????? ??????????? ?????
         if(Stelth==1)
            PutLable("SL"+DoubleToString(Ask,_Digits),TimeCurrent(),NormalizeDouble(Ask-SL*_Point,_Digits),LableClr);
         if(Stelth==1)
            PutLable("TP"+DoubleToString(Ask,_Digits),TimeCurrent(),NormalizeDouble(Ask+TP*_Point,_Digits),LableClr);
        }
      //--- ??? ??????? ? ?????? ?? ???????
      if(PositionsTotal()<1 && Sell)
        {
         //--- ????????? ?????
         if(SL==0)
            stop=0;
         else
            stop=NormalizeDouble(Bid+SL*_Point,_Digits);
         if(TP==0)
            take=0;
         else
            take=NormalizeDouble(Bid-TP*_Point,_Digits);
         //--- ????? ???????????
         if(Stelth==1)
           {
            stop=0;
            take=0;
           }
         //--- ????????? ????? ?? ???????
         if(Autostop)//stopSell
           {
            stop=NormalizeDouble(iHigh(Symbol(),AutostopTime,iHighest(NULL,AutostopTime,AutostopSellMode,AutostopPeriod,0)),_Digits);
            if(stop<NormalizeDouble(Bid+SL*_Point,_Digits))
              {
               stop=NormalizeDouble(iHigh(Symbol(),AutostopTime,iHighest(NULL,AutostopTime,AutostopSellMode,AutostopPeriod,0)),_Digits)+40.00;
              }

           }
         if(AutoTP)//TPSell
           {
            take=NormalizeDouble(iLow(Symbol(),AutoTPTime,iLowest(NULL,AutoTPTime,AutoTPSellMode,AutoTPPeriod,0)),_Digits);
            if(take>NormalizeDouble(Bid+SL*_Point,_Digits))
              {
               take=NormalizeDouble(iLow(Symbol(),AutoTPTime,iLowest(NULL,AutoTPTime,AutoTPSellMode,AutoTPPeriod,0)),_Digits)-40.00;
              }

           }
         trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,Volume(),Bid,stop,take);
         if(Stelth==1)
            PutLable("TP"+DoubleToString(Bid,_Digits),TimeCurrent(),NormalizeDouble(Bid-TP*_Point,_Digits),LableClr);
         if(Stelth==1)
            PutLable("SL"+DoubleToString(Bid,_Digits),TimeCurrent(),NormalizeDouble(Bid+SL*_Point,_Digits),LableClr);
        }
     }
//--- ???????? ?? ???????
//--- ??????? ??????? ? ????? ?????
   if(PositionSelect(_Symbol) && Stelth==1)
     {
      //--- ??????? ???????
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         //--- ??????? ??????
         pr=(Bid-PositionGetDouble(POSITION_PRICE_OPEN))/_Point;
         if(pr>=TP)
           {
            //--- ????????? ???????
            trade.PositionClose(_Symbol);
           }
         if(pr<=-SL)
           {
            //--- ????????? ???????
            trade.PositionClose(_Symbol);
           }
        }
      //--- ??????? ???????
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
        {
         //--- ??????? ??????
         pr=(PositionGetDouble(POSITION_PRICE_OPEN)-Bid)/_Point;
         if(pr>=TP)
           {
            //--- ????????? ???????
            trade.PositionClose(_Symbol);
           }
         if(pr<=-SL)
           {
            //--- ????????? ???????
            trade.PositionClose(_Symbol);
           }
        }
     }

  }
//+------------------------------------------------------------------+
//| ??????????? ????                                                 |
//+------------------------------------------------------------------+
void PutLable(const string name="",datetime time=0,double price=0,const color clr=clrGreen)
  {
//--- ??????? ???????? ??????
   ResetLastError();
//--- ??????? ?????
   if(!ObjectCreate(0,name,OBJ_ARROW_LEFT_PRICE,0,time,price))
     {
      Print(__FUNCTION__,
            ": ?? ??????? ??????? ????? ??????? ?????! ??? ?????? = ",GetLastError());
      return;
      //--- ????????? ???? ?????
      ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
      //--- ????????? ????? ??????????? ?????
      ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_SOLID);
      //--- ????????? ?????? ?????
      ObjectSetInteger(0,name,OBJPROP_WIDTH,2);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsNewBar(string symbol,ENUM_TIMEFRAMES timeframe)
  {
//---- ??????? ????? ????????? ???????? ????
   datetime TNew=datetime(SeriesInfoInteger(symbol,timeframe,SERIES_LASTBAR_DATE));
   datetime m_TOld=0;
//--- ???????? ?? ????????? ?????? ????
   if(TNew!=m_TOld && TNew)
     {
      m_TOld=TNew;
      //--- ???????? ????? ???!
      return(true);
      Print("????? ???!");
     }
//--- ????? ????? ???? ???!
   return(false);
  }
//+------------------------------------------------------------------+
//| ??????? ??? ? ??????????? ?? ??????????? ???????                 |
//+------------------------------------------------------------------+
double Volume(void)
  {
   double lot=Lot;
//--- ??????? ?????? ? ???????
   HistorySelect(0,TimeCurrent());
//--- ?????? ? ???????
   int orders=HistoryDealsTotal();
//--- ????? ????????? ??????
   ulong ticket=HistoryDealGetTicket(orders-1);
   if(ticket==0)
     {
      Print("??? ?????? ? ???????! ");
      lot=Lot;
     }
//--- ?????? ??????
   double profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
//--- ??? ??????
   double lastlot=HistoryDealGetDouble(ticket,DEAL_VOLUME);
//--- ?????? ?????????????
   if(profit<0.0)
     {
      //--- ??????????? ????????? ???
      lot=NormalizeDouble(lastlot*KLot,2);
      Print(" C????? ??????? ?? ?????! ");
     }
//--- ???????? ??? ? ????????????
   double minvol=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   if(lot<minvol)
      lot=minvol;
//--- ???? ??? ?????? ????????????? ?? ????????? ???
   if(lot>MaxLot)
      lot=Lot;
//--- ?????????? ???????? ?????
   return(lot);
  }
//+------------------------------------------------------------------+
//| ??????? ??? ????????? ???????? ??????                            |
//+------------------------------------------------------------------+
int LastDealType(void)
  {
   int type=0;
//--- ??????? ?????? ? ???????
   HistorySelect(0,TimeCurrent());
//--- ?????? ? ???????
   int orders=HistoryDealsTotal();
//--- ????? ????????? ??????
   ulong ticket=HistoryDealGetTicket(orders-1);
//--- ??? ?????? ? ???????
   if(ticket==0)
     {
      Print("??? ?????? ? ???????! ");
      type=0;
     }
   if(ticket>0)
     {
      //--- ????????? ?????? BUY
      if(HistoryDealGetInteger(ticket,DEAL_TYPE)==DEAL_TYPE_BUY)
        {
         type=2;
        }
      //--- ????????? ?????? SELL
      if(HistoryDealGetInteger(ticket,DEAL_TYPE)==DEAL_TYPE_SELL)
        {
         type=1;
        }
     }
//---
   return(type);
  }
//---------------------------------------------------------------------
// The handler of the event of completion of another test pass:
//---------------------------------------------------------------------
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
   double  param = 0.0;

//  Balance max + min Drawdown + Trades Number:
   double  balance = TesterStatistics(STAT_PROFIT);
   if(balance<=0)
     {
      param=0;
      return(param);
     }

   double  min_dd = TesterStatistics(STAT_BALANCE_DD);
   double win = TesterStatistics(STAT_PROFIT_TRADES);
   if(min_dd > 0.0)
     {
      min_dd = 1.0 / min_dd;
     }
   double  trades_number = TesterStatistics(STAT_TRADES);
   param = ((balance * trades_number)/1000) * min_dd ;


   return(param);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool RefreshRates(string sym)
  {
   double ask = SymbolInfoDouble(sym,SYMBOL_ASK);
   double bid = SymbolInfoDouble(sym,SYMBOL_BID);
//--- protection against the return value of "zero"
   if(ask==0 || bid==0)
      return(false);
//---
   return(true);
  }


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int SAROnInit()
  {
//get the handle of the iSar indicator
   Sar_base=iSAR(Symbol(),base_tf,sar_step,maximum_step);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void SAROnTick()
  {
//--- search for iSar
   double Sar_array_base[];//--- declaration of array for writing the values of the buffers of the indicator iSar
//CopyBuffer(Sar_base,0,TimeCurrent(),Bars(Symbol(),base_tf),Sar_array_base);// --- filling with the data of the buffer
   CopyBuffer(Sar_base,0,TimeCurrent(),3,Sar_array_base);// --- filling with the data of the buffer
   ArraySetAsSeries(Sar_array_base,true);// --- indexing as in timeseries
//---
//---search for high and low
   double High_base[],Low_base[];
   ArraySetAsSeries(High_base,true);
   ArraySetAsSeries(Low_base,true);
   CopyHigh(Symbol(),base_tf,0,10,High_base);
   CopyLow(Symbol(),base_tf,0,10,Low_base);
//---
//--- searcg for time of iSar
   datetime Sar_time_base[];
   ArraySetAsSeries(Sar_time_base,true);
   CopyTime(Symbol(),base_tf,0,10,Sar_time_base);
//---
//--- order modification

   double OP_double,TP_double;
   int P_type,P_opentime;
   string P_symbol;
   if(PositionsTotal()>0)
     {
      for(int i=PositionsTotal(); i>=0; i--)
        {
         if(PositionGetTicket(i))
           {
            OP_double=double (PositionGetDouble(POSITION_PRICE_OPEN));
            TP_double=double (PositionGetDouble(POSITION_TP));
            P_type=int(PositionGetInteger(POSITION_TYPE));
            P_opentime=int(PositionGetInteger(POSITION_TIME));
            P_symbol=string(PositionGetString(POSITION_SYMBOL));
            if(P_symbol==Symbol())
              {
               if(P_type==0 && Sar_array_base[1]>OP_double && Sar_array_base[1]<Low_base[1] && Sar_time_base[1]>P_opentime)
                 {
                  trade.PositionModify(PositionGetInteger(POSITION_TICKET),Sar_array_base[1],TP_double);
                 }
               if(P_type==1 && Sar_array_base[1]<OP_double && Sar_array_base[1]>High_base[1] && Sar_time_base[1]>P_opentime)
                 {
                  trade.PositionModify(PositionGetInteger(POSITION_TICKET),Sar_array_base[1],TP_double);
                 }
              }
           }
        }
     }
//---
  }
//+------------------------------------------------------------------+