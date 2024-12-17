//+------------------------------------------------------------------+
//|                                                 Sivan Pachai.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input string               startWorkingTime   = "8:00"; // Expert | Start Time 1
input string               endWorkingTime     = "12:00"; // Expert | End Time 1

struct workingHours
   {
    bool                       startTimeError;
    bool                       endTimeError;
    int                        startHour;
    int                        startMinute;
    int                        endHour;
    int                        endMinute;
    datetime                   time_0;
    datetime                   time_1;
    datetime                   time_2;

    void             Init(string startTime, string endTime)
       {
        //--- Start time check
        //--- check length start time parameter
        if(StringLen(startTime) != 5)
           {
            PrintFormat("ERROR | Wrong work EA timesession length [%d], should be 5 symbols. Check Start Time", StringLen(startTime));
            startTimeError = true;
            return;
           }
        //--- Checking for symbol ":" in inputTime
        if(StringSubstr(startTime, 2, 1) != ":")
           {
            Print("ERROR | Wrong type the specified EA timesession [%d], should be hours:minutes. Check Start Times");
            startTimeError = true;
            return;
           }
        //--- Check  inputTime hour for validity
        string inputTimeArray[];
        int result = StringSplit(startTime, StringGetCharacter(":", 0), inputTimeArray);
        if(!(StringToInteger(inputTimeArray[0]) >= 0 && StringToInteger(inputTimeArray[0]) < 24))
           {
            PrintFormat("ERROR | Wrong entry of the Expert Advisor working time parameter, check the number of hours must be 0 - 24 now %d", StringToInteger(inputTimeArray[0]));
            startTimeError = true;
            return;
           }
        //--- Check  inputTime minute for validity
        if(!(StringToInteger(inputTimeArray[1]) >= 0 && StringToInteger(inputTimeArray[1]) < 60))
           {
            PrintFormat("ERROR | Wrong entry of the Expert Advisor working time parameter, check the number of minutes must be 0 - 59 now %d", StringToInteger(inputTimeArray[1]));
            startTimeError = true;
            return;
           }
        startHour = (int)StringToInteger(inputTimeArray[0]) ;
        startMinute = (int)StringToInteger(inputTimeArray[1]) ;
        //--- End time check
        //--- check length start time parameter
        if(StringLen(endTime) != 5)
           {
            PrintFormat("ERROR | Wrong work EA timesession length [%d], should be 5 symbols. Check End Time", StringLen(endTime));
            endTimeError = true;
            return ;
           }
        //--- Checking for symbol ":" in inputTime
        if(StringSubstr(endTime, 2, 1) != ":")
           {
            Print("ERROR | Wrong type the specified EA timesession [%d], should be hours:minutes. Check End Times");
            endTimeError = true;
            return;
           }
        //--- Check  inputTime hour for validity
        ArrayResize(inputTimeArray, 0);
        result = StringSplit(endTime, StringGetCharacter(":", 0), inputTimeArray);
        if(!(StringToInteger(inputTimeArray[0]) >= 0 && StringToInteger(inputTimeArray[0]) < 24))
           {
            PrintFormat("ERROR | Wrong entry of the Expert Advisor working time parameter, check the number of hours must be 0 - 24 now %d", StringToInteger(inputTimeArray[0]));
            endTimeError = true;
            return ;
           }
        //--- Check  inputTime minute for validity
        if(!(StringToInteger(inputTimeArray[1]) >= 0 && StringToInteger(inputTimeArray[1]) < 60))
           {
            PrintFormat("ERROR | Wrong entry of the Expert Advisor working time parameter, check the number of minutes must be 0 - 59 now %d", StringToInteger(inputTimeArray[1]));
            endTimeError = true;
            return;
           }
        endHour = (int)StringToInteger(inputTimeArray[0]) ;
        endMinute = (int)StringToInteger(inputTimeArray[1]);
        return;
       }
    bool             check()
       {
        if((startHour == 0 && endHour == 0) && (endHour == 0 && endMinute == 0))
            return (true);
        //---
        time_0 = (int)TimeCurrent();                                                             // Current Time(now)
        time_1 = int(iTime(_Symbol, PERIOD_D1, 0) + startHour * 60 * 60 + startMinute * 60);     // Start time of EA
        time_2 = int(iTime(_Symbol, PERIOD_D1, 0) + endHour * 60 * 60 + endMinute * 60);         // End time EA
        //---
        if(time_1 < time_2 && time_1 <= time_0 && time_0 <= time_2)
            return (true);
        if(time_1 > time_2 && (time_0 >= time_1 || time_0 <= time_2))
            return (true);
        return (false);
       }
   };

datetime                   checkNewBar        = 0;
workingHours               workingTime;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
   {
    workingTime.Init(startWorkingTime, endWorkingTime);
//--- create timer
    EventSetTimer(60);
//---
    return(INIT_SUCCEEDED);
   }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
   {
//--- destroy timer
    EventKillTimer();
   }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
   {
//---
    if(!workingTime.check())
       {
        Print("Now is not working hours");
        return;
       }
    Print("Working hours");
   }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
   {
//---
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool checkNewBar()
   {
    if(iTime(NULL, PERIOD_CURRENT, 0) > checkNewBar)
       {
        checkNewBar = iTime(NULL, PERIOD_CURRENT, 0);
        return true;
       }
    return false;
   }
//+------------------------------------------------------------------+
