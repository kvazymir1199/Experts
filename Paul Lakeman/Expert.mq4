//+------------------------------------------------------------------+
//|                                                       Expert.mq4 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <Indicators/Trend.mqh>
#include <Indicators/Oscilators.mqh>
#include <Tools/DateTime.mqh>
#include <stdlib.mqh>
CDateTime time;

//+------------------------------------------------------------------+
//|                    MA Indicator Parameters                       |
//+------------------------------------------------------------------+

input ENUM_TIMEFRAMES      maTimeFrame          = PERIOD_H4;   // MA | TimeFrame
input int                  maPeriod             = 20;          // MA | Period 
input int                  maShift              = 0;           // Ma | Shift
input ENUM_APPLIED_PRICE   maAppliedPrice       = PRICE_CLOSE; // Ma | Price
input ENUM_MA_METHOD       maMethod             = MODE_SMA;    // Ma | Mode

//+------------------------------------------------------------------+
//|                    RSI Indicator Parameters                      |
//+------------------------------------------------------------------+

input ENUM_TIMEFRAMES      rsiTimeframe            =  PERIOD_M30;  // RSI |  TimeFrame
input int                  rsiPeriod               =  14;          // RSI |  Period 
input ENUM_APPLIED_PRICE   rsiAppliedPrice         =  PRICE_CLOSE; // RSI |  Price
input int                  rsi_lower               =  30;          // RSI |  Lower Level 
input int                  rsi_upper               =  30;          // RSI |  Upper Level
//+------------------------------------------------------------------+
//|                    Working Days Parameters                       |
//+------------------------------------------------------------------+

input bool                 isMondayAllowed         = true;      // Trading Days | Mondey on/off
input bool                 isTuesdayAllowed        = true;      // Trading Days | Tuesday on/off
input bool                 isWednesdayAllowed      = true;      // Trading Days | Wednesday on/off
input bool                 isThursdayAllowed       = true;      // Trading Days | Tursday on/off
input bool                 isFridayAllowed         = true;      // Trading Days | Friday on/off
input bool                 isSaturdayAllowed       = true;      // Trading Days | Saturday on/off
input bool                 isSundayAllowed         = true;      // Trading Days | Sunday on/off
//+------------------------------------------------------------------+
//|                    Order Parameters                              |
//+------------------------------------------------------------------+
input int                  inputStoploss           = 300;       // Order | Stoploss in points
input int                  inputTakeprofit         = 300;       // Order | TakeProfit in points
input double               inputLots               = 0.01;      // Order | Lots 
input int                  inputMagic              = 12345;     // Order | Magic
input bool                 isBreakEvenOn           = true;      // Order | Breakeven on/off
input int                  breakEvenStart          = 20;        // Order | BreakEven Start points
input int                  breakEvenAdd            = 10;        // Order | BreakEven Extra Add points
//+------------------------------------------------------------------+
//|                   Trading Currencies                             |
//+------------------------------------------------------------------+
input bool                 isAllPairForTrading     = true;      // Expert | True: Currenies in Market / False: All Broker Symbols
datetime                   lastCheckTime           = 0;

string                     tradingSymbols[];

CiMA ma;
CiRSI rsi;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
   {
    lastCheckTime = iTime(NULL, PERIOD_CURRENT, 0);
    onInit();
    return(INIT_SUCCEEDED);
   }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
   {
//---
   }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
   {
//---
    onTick();
   }
//+------------------------------------------------------------------+
double n(const double data = 0, const int digits = -1)
   {
    return NormalizeDouble(data, digits == -1 ? _Digits : digits);
   }
//+------------------------------------------------------------------+
void errorMessage(string errorFunction)
   {
    PrintFormat("ERROR | %s: %s", errorFunction, ErrorDescription(GetLastError()));
   }
//+------------------------------------------------------------------+
void addGlobalSymbolsToCheckListSymbols()
   {
    if(IsTesting())
       {
        addElement(tradingSymbols, Symbol());
        return;
       }
    int total = GlobalVariablesTotal() - 1;
    for(int i = total; i >= 0; i--)
       {
        string name = GlobalVariableName(i);
        double value = GlobalVariableGet(name);
        if(value > 0)
            addElement(tradingSymbols, name);
       }
   }
//+------------------------------------------------------------------+
void createGlobalSymbols(bool mode = true)
   {
    int total = SymbolsTotal(mode);
    for(int i = 0; i < total; i++)
       {
        string name = SymbolName(i, mode);
        if(!GlobalVariableCheck(name))
           {
            PrintFormat("GLOBAL with name: %s not founded. Create new GLOBAL!");
            GlobalVariableSet(name, 1);
            continue;
           }
        double var =  GlobalVariableGet(name);
        PrintFormat("GLOBAL with name: %s already exists!", name);
       }
   }
//+------------------------------------------------------------------+
template <typename T>
void addElement(T & array[], T ticket)
   {
    int newSize = ArraySize(array) + 1;
    ArrayResize(array, newSize);
    array[ArraySize(array) - 1] = ticket;
   }
//+------------------------------------------------------------------+
void onTick()
   {
    breakEven();
    if(!checkNewBar())
        return;
    bool tradingForToday = checkTradingOnCurrentDay();
    if(!tradingForToday)
        return;
    int total = ArraySize(tradingSymbols) - 1;
    for(int i = total; i >= 0; i--)
       {
        string symbol = tradingSymbols[i];
        if(checkOpenOrders(symbol))
            continue;
        if(checkOpenTradeToday(symbol))
            return;
        int SignalType = checkConditionForOpenOrder(symbol);
        if(SignalType == -1)
            return;
        createOrder(SignalType, symbol);
       }
   }
//+------------------------------------------------------------------+
void onInit()
   {
    createGlobalSymbols();
    addGlobalSymbolsToCheckListSymbols();
   }
//+------------------------------------------------------------------+
int checkConditionForOpenOrder(string _symbol)
   {
    ma.Create(_symbol, maTimeFrame, maPeriod, maShift, maMethod, maAppliedPrice);
    rsi.Create(_symbol, rsiTimeframe, rsiPeriod, rsiAppliedPrice);
    if(ma.GetData(1) > iClose(_symbol, maTimeFrame, 1) && rsi.GetData(1) <= rsi_lower)
        return 0;
    if(ma.GetData(1) < iClose(_symbol, maTimeFrame, 1) && rsi.GetData(1) >= rsi_upper)
        return 1;
    return -1;
   }
//+------------------------------------------------------------------+
bool checkTradingOnCurrentDay()
   {
    MqlDateTime currentTime;
    TimeToStruct(TimeCurrent(), currentTime);
    return checkWorkingDaysPermisions(currentTime.day_of_week);
   }
//+------------------------------------------------------------------+
bool checkWorkingDaysPermisions(int day_of_week)
   {
    switch(day_of_week)
       {
        case 0 :
            return isSundayAllowed;
        case 1 :
            return isMondayAllowed;
        case 2 :
            return isTuesdayAllowed;
        case 3 :
            return isWednesdayAllowed;
        case 4 :
            return isThursdayAllowed;
        case 5 :
            return isFridayAllowed;
        case 6 :
            return isSaturdayAllowed;
        default:
            return false;
       }
   }
//+------------------------------------------------------------------+
int createOrder(int cmd, string _symbol)
   {
    RefreshRates();
    ResetLastError();
    double price = cmd == OP_BUY ? n(MarketInfo(_symbol, MODE_ASK)) : n(MarketInfo(_symbol, MODE_BID));
    double sl = inputStoploss == 0 ? 0 : cmd == OP_BUY ? price - inputStoploss * Point : price + inputStoploss * Point;
    double tp = inputTakeprofit == 0 ? 0 : cmd == OP_BUY ? price + inputTakeprofit * Point : price - inputTakeprofit * Point;
    color orderColor = cmd == OP_BUY ? clrGreen : clrRed;
    int ticket = OrderSend(_symbol, cmd, getLotSize(_symbol), price, 12, sl, tp, "", inputMagic, 0, orderColor);
    if(ticket < 0)
       {
        PrintFormat("Try open order with params: %s | %s | %s with lots: %s",
                    DoubleToStr(price),
                    DoubleToStr(sl),
                    DoubleToStr(tp),
                    DoubleToStr(getLotSize(_symbol)));
        errorMessage("Order Send");
       }
    return ticket;
   }
//+------------------------------------------------------------------+
void breakEven()
   {
    if(!isBreakEvenOn)
        return;
    int total = OrdersTotal() - 1;
    for(int i = total; i >= 0; i--)
       {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;
        if(OrderMagicNumber() != inputMagic)
            continue;
        bool condition = OrderType() == OP_BUY ? n(Bid) > OrderOpenPrice() + (breakEvenStart * 10)  * Point && OrderStopLoss() < OrderOpenPrice() :
                         n(Ask) < OrderOpenPrice() - (breakEvenStart * 10)  * Point && OrderStopLoss() > OrderOpenPrice();
        if(condition)
           {
            double newStoploss = OrderType()
                                 == OP_BUY ? OrderOpenPrice() + (breakEvenAdd * 10)  * Point : OrderOpenPrice() - (breakEvenAdd * 10) * Point;
            bool res = OrderModify(OrderTicket(), OrderOpenPrice(), newStoploss, OrderTakeProfit(), 0, clrNONE);
            if(!res)
                errorMessage("OrderModify BreakEven");
           }
       }
   }
//+------------------------------------------------------------------+
bool checkNewBar()
   {
    if(iTime(NULL, PERIOD_CURRENT, 0) > lastCheckTime)
       {
        lastCheckTime = iTime(NULL, PERIOD_CURRENT, 0);
        return true;
       }
    return false;
   }
//+------------------------------------------------------------------+
int countLoseOrders(string _symbol)
   {
    int count = 0;
    int total = OrdersHistoryTotal() - 1;
    for(int i = total; i >= 0; i--)
       {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
            continue;
        if(!(OrderMagicNumber() == inputMagic && OrderSymbol() == _symbol))
            continue;
        if(OrderProfit() + OrderSwap() + OrderCommission() < 0)
            count++;
        if(OrderProfit() + OrderSwap() + OrderCommission() > 0)
            break;
       }
    return count;
   }
//+------------------------------------------------------------------+
double getLotSize(string _symbol)
   {
    int getTotalLoss = countLoseOrders(_symbol);
    if(getTotalLoss == 0)
        return inputLots;
    double newlotsize = 0;
    for(int i = getTotalLoss; i > 0; i--)
       {
        newlotsize += inputLots * 2;
       }
    return NormalizeDouble(newlotsize, 2);
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkOpenTradeToday(string _symbol)
   {
    int total = OrdersHistoryTotal() - 1;
    for(int i = total; i >= 0; i--)
       {
        if(!OrderSelect(i, SELECT_BY_POS,MODE_HISTORY))
            continue;
        if(!(OrderMagicNumber() == inputMagic && OrderSymbol() == _symbol))
            continue;
        PrintFormat("Order: %d", OrderTicket());
        datetime dayTime = iTime(_symbol, PERIOD_D1, 0);
        if(OrderCloseTime() > dayTime || OrderOpenTime() > dayTime)
            return true;
       }
    return false;
   }
//+------------------------------------------------------------------+
bool checkOpenOrders(string _symbol)
   {
    for(int i = OrdersTotal() - 1; i >= 0; i--)
       {
        if(!OrderSelect(i, SELECT_BY_POS))
            continue;
        if(!(OrderMagicNumber() == inputMagic && OrderSymbol() == _symbol))
            continue;
        return true;
       }
    return false;
   }
//+------------------------------------------------------------------+
