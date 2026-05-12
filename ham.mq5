#property copyright "Talex / MT5 port by Codex"
#property link      "tan@gazinter.net"
#property version   "1.01"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_label1  "PatternZigZag"
#property indicator_type1   DRAW_SECTION
#property indicator_color1  clrNONE

input bool   FuturePattern  = false;
input bool   ExtSave        = false;
input int    ExtDepth       = 0;
input int    ExtPoint       = 5;
input int    minDepth       = 3;
input int    maxDepth       = 50;
int          ExtIndicator   = 0;
input double ExtDopusk      = 0.05;
input double TimeDopusk     = 0.20;
input bool   Gartley        = true;
input bool   Pattern_50     = true;
input bool   ABCD           = true;
input bool   WolfWaves      = false;
input bool   SweetZoneStart = true;
input bool   SweetZoneEnd   = true;
input color  SZScolor       = clrBlue;
input color  SZEcolor       = clrDarkGreen;
input color  ExtColorGartley= clrMidnightBlue;
input color  ExtColorRet    = clrLime;
enum ENUM_ENTRY_POINT_MODE
{
   ENTRY_POINT_B_ONLY = 0,
   ENTRY_POINT_C_ONLY = 1,
   ENTRY_POINT_BOTH   = 2
};
input ENUM_ENTRY_POINT_MODE EntryPointMode     = ENTRY_POINT_BOTH;
input int    TDIRSILength                      = 13;
input int    TDIVolatilityBandLength           = 34;
input int    TDISignalLineLength               = 7;
input bool   ShowEntryPriceLine                = true;
input bool   ShowEntryLabel                    = true;
input color  LongEntryColor                    = clrLime;
input color  ShortEntryColor                   = clrRed;
input int    EntryArrowOffsetPoints            = 20;
input bool   MobileAlerts                      = true;
input bool   TerminalPopups                    = false;

double zz[];
double g_tdi_rsi[];
double g_tdi_signal[];
double g_tdi_upper[];
double g_tdi_lower[];

int      g_endbar   = 0;
double   g_endpr    = 0.0;
bool     g_fl       = false;
string   g_save     = "";
int      g_pixels_x = 0;
int      g_pixels_y = 0;
int      g_bars     = 0;

datetime g_time[];
double   g_high[];
double   g_low[];
double   g_close[];

int      g_points_to_use = 5;
int      g_min_depth     = 3;
int      g_max_depth     = 50;
int      g_tdi_rsi_handle = INVALID_HANDLE;

int      g_last_gartley_x = -1, g_last_gartley_a = -1, g_last_gartley_b = -1, g_last_gartley_c = -1, g_last_gartley_d = -1;
int      g_last_50_x      = -1, g_last_50_a      = -1, g_last_50_b      = -1, g_last_50_c      = -1, g_last_50_d      = -1;
int      g_last_abcd_a    = -1, g_last_abcd_b    = -1, g_last_abcd_c    = -1, g_last_abcd_d    = -1;
int      g_last_ww_p1     = -1, g_last_ww_p2     = -1, g_last_ww_p3     = -1, g_last_ww_p4     = -1, g_last_ww_p5     = -1;

string   g_last_mobile_entry_key = "";

int      TfSeconds();
string   TimeFrame();
string   SaveSuffix();
datetime TimeAtShift(const int shift);
datetime MidTime(const datetime t1,const datetime t2);
void     RefreshChartMetrics();
void     ResetState();
bool     PrepareSeries(const int rates_total,
                       const datetime &time[],
                       const double &high[],
                       const double &low[],
                       const double &close[]);
bool     CalculateTDI(const int rates_total);
double   SimpleAverage(const double &source[],const int start,const int period);
double   StandardDeviation(const double &source[],const int start,const int period,const double mean);
bool     IsSwingLow(const int shift);
bool     IsSwingHigh(const int shift);
bool     FindPreviousSwingOfType(const int shift,const bool bullish,int &previous_shift);
bool     HasTDIDivergence(const int shift,const bool bullish);
bool     EntryPointEnabled(const string point_name);
void     EvaluateEntrySignals(const string NamePattern,const string BullBear,const int Depth,const int B,const int C);
void     CreateEntrySignal(const string NamePattern,const string BullBear,const string PointName,const int Depth,const int shift,const bool bullish);
void     TryMobileEntryAlert(const string &suffix,const string &NamePattern,const string &BullBear,const string &PointName,const double entry_price,const bool bullish);
bool     CreateArrowMarker(const string name,const datetime t1,const double p1,const color clr,const int arrow_code,const ENUM_ARROW_ANCHOR anchor);

int      SeriesLowest(const double &source[],const int count,const int start);
int      SeriesHighest(const double &source[],const int count,const int start);
double   funk1(const int zzbarlow,const int depth);
void     ZZTalex(const int depth);

void     GartleyPatternsSearch(const int X,const int A,const int B,const int C,const int D,const int Depth);
void     Patterns50Search(const int X,const int A,const int B,const int C,const int D,const int Depth);
void     ABCDSearch(const int A,const int B,const int C,const int D,const int Depth);
void     WolfWavesSearch(int P1,int P2,int P3,int P4,int P5,const int Depth);

void     CorrectObject();
void     Commentarii();
string   ExtRet(const double enterret,const double minret,const double maxret);
void     TargetAndFibo(const string NamePattern,const string BullBear,const string MinMax,const double maxret,const int Depth,const int X,const int A,const int B,const int C,const int D);
void     CreateFuturePattern(const int X4,const int A4,const int B4,const int C4,const int Depth,const double minD,const double maxD,const double maxAC,const double retXB,const double retAC,const string BullBear,const string NamePattern,const string MinMax);
void     CreateRealPattern(const string NamePattern,const string BullBear,const int Depth,const int X,const int A,const int B,const int C,const int D,const double retXB,const double retAC,const double retBD,const double retXD,const double minret,const double maxret);
void     WolfWavesDraw(const string NamePattern,const string BullBear,const int Depth,
                       const datetime t1,const double p1,const datetime t2,const double p2,const datetime t3,const double p3,const datetime t4,const double p4,
                       const datetime t5,const double p5,const datetime t6,const double p6,const datetime t7,const double p7,const datetime t8,const double p8,const datetime t9,const double p9);

double   TextEdit();
double   AngleEdit(const int BarPoint1,const double PricePoint1,const int BarPoint2,const double PricePoint2);

bool     DeleteIfExists(const string name);
bool     CreateTrend(const string name,const datetime t1,const double p1,const datetime t2,const double p2,const color clr,const ENUM_LINE_STYLE style=STYLE_SOLID,const int width=1,const bool ray=false);
bool     CreateTriangle(const string name,const datetime t1,const double p1,const datetime t2,const double p2,const datetime t3,const double p3,const color clr,const string label);
bool     CreateTextLabel(const string name,const datetime t1,const double p1,const string text,const color clr,const double angle=0.0);
bool     CreateFibo(const string name,const datetime t1,const double p1,const datetime t2,const double p2,const string NamePattern);
string   PatternLabel(const string NamePattern,const string BullBear,const int Depth);
bool     IsTriangleObject(const string name);
string   TriangleLabel(const string name);

int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME,"Search Patterns MT5");
   SetIndexBuffer(0,zz,INDICATOR_DATA);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   ArraySetAsSeries(zz,true);

    g_tdi_rsi_handle = iRSI(_Symbol,_Period,TDIRSILength,PRICE_CLOSE);
    if(g_tdi_rsi_handle==INVALID_HANDLE)
       return(INIT_FAILED);

   RefreshChartMetrics();
   ResetState();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   Comment("");
   if(g_tdi_rsi_handle!=INVALID_HANDLE)
      IndicatorRelease(g_tdi_rsi_handle);
   for(int i=ObjectsTotal(0,-1,-1)-1; i>=0; --i)
   {
      string name = ObjectName(0,i,-1,-1);
      if(StringFind(name,"Real",0)==0 || StringFind(name,"Future",0)==0 || StringFind(name,"Entry",0)==0)
         ObjectDelete(0,name);
   }
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total<20)
      return(rates_total);

   g_points_to_use = MathMax(5,ExtPoint);
   g_min_depth     = (ExtDepth>0 ? ExtDepth : MathMax(1,minDepth));
   g_max_depth     = (ExtDepth>0 ? ExtDepth : MathMax(g_min_depth,maxDepth));

   if(!PrepareSeries(rates_total,time,high,low,close))
      return(prev_calculated);

   if(!CalculateTDI(rates_total))
      return(prev_calculated);

   RefreshChartMetrics();
   ResetState();
   ArrayInitialize(zz,0.0);

   for(int depth=g_min_depth; depth<=g_max_depth; ++depth)
   {
      ZZTalex(depth);

      int points[];
      ArrayResize(points,g_points_to_use);
      ArrayInitialize(points,-1);

      int j=0;
      for(int i=0; i<g_bars && j<g_points_to_use; ++i)
      {
         if(zz[i]!=0.0)
            points[j++] = i;
      }

      if(j<5)
         continue;

      int X = points[g_points_to_use-1];
      int A = points[g_points_to_use-2];
      int B = points[g_points_to_use-3];
      int C = points[g_points_to_use-4];
      int D = points[g_points_to_use-5];

      if(Gartley)
         GartleyPatternsSearch(X,A,B,C,D,depth);
      if(Pattern_50)
         Patterns50Search(X,A,B,C,D,depth);
      if(ABCD)
         ABCDSearch(A,B,C,D,depth);
      if(WolfWaves)
         WolfWavesSearch(X,A,B,C,D,depth);
   }

   CorrectObject();
   Commentarii();
   ChartRedraw(0);
   return(rates_total);
}

void ResetState()
{
   g_save = SaveSuffix();
}

bool PrepareSeries(const int rates_total,
                   const datetime &time[],
                   const double &high[],
                   const double &low[],
                   const double &close[])
{
   g_bars = rates_total;
   ArrayResize(g_time,rates_total);
   ArrayResize(g_high,rates_total);
   ArrayResize(g_low,rates_total);
   ArrayResize(g_close,rates_total);

   ArraySetAsSeries(g_time,true);
   ArraySetAsSeries(g_high,true);
   ArraySetAsSeries(g_low,true);
   ArraySetAsSeries(g_close,true);

   ArrayCopy(g_time,time,0,0,WHOLE_ARRAY);
   ArrayCopy(g_high,high,0,0,WHOLE_ARRAY);
   ArrayCopy(g_low,low,0,0,WHOLE_ARRAY);
   ArrayCopy(g_close,close,0,0,WHOLE_ARRAY);
   return(true);
}

bool CalculateTDI(const int rates_total)
{
   if(g_tdi_rsi_handle==INVALID_HANDLE)
      return(false);

   ArrayResize(g_tdi_rsi,rates_total);
   ArrayResize(g_tdi_signal,rates_total);
   ArrayResize(g_tdi_upper,rates_total);
   ArrayResize(g_tdi_lower,rates_total);
   ArraySetAsSeries(g_tdi_rsi,true);
   ArraySetAsSeries(g_tdi_signal,true);
   ArraySetAsSeries(g_tdi_upper,true);
   ArraySetAsSeries(g_tdi_lower,true);

   if(CopyBuffer(g_tdi_rsi_handle,0,0,rates_total,g_tdi_rsi)<=0)
      return(false);

   for(int i=rates_total-1; i>=0; --i)
   {
      if(i+TDISignalLineLength<=rates_total)
         g_tdi_signal[i]=SimpleAverage(g_tdi_rsi,i,TDISignalLineLength);
      else
         g_tdi_signal[i]=EMPTY_VALUE;

      if(i+TDIVolatilityBandLength<=rates_total)
      {
         double mean = SimpleAverage(g_tdi_rsi,i,TDIVolatilityBandLength);
         double dev  = StandardDeviation(g_tdi_rsi,i,TDIVolatilityBandLength,mean);
         g_tdi_upper[i]=mean+(1.6185*dev);
         g_tdi_lower[i]=mean-(1.6185*dev);
      }
      else
      {
         g_tdi_upper[i]=EMPTY_VALUE;
         g_tdi_lower[i]=EMPTY_VALUE;
      }
   }
   return(true);
}

double SimpleAverage(const double &source[],const int start,const int period)
{
   if(period<=0 || start<0 || start+period>ArraySize(source))
      return(EMPTY_VALUE);

   double sum=0.0;
   for(int i=0; i<period; ++i)
      sum += source[start+i];
   return(sum/period);
}

double StandardDeviation(const double &source[],const int start,const int period,const double mean)
{
   if(period<=1 || start<0 || start+period>ArraySize(source))
      return(0.0);

   double sum=0.0;
   for(int i=0; i<period; ++i)
   {
      double delta = source[start+i]-mean;
      sum += delta*delta;
   }
   return(MathSqrt(sum/period));
}

bool IsSwingLow(const int shift)
{
   return(shift>=0 && shift<g_bars && zz[shift]!=0.0 && MathAbs(zz[shift]-g_low[shift])<=(_Point*0.5));
}

bool IsSwingHigh(const int shift)
{
   return(shift>=0 && shift<g_bars && zz[shift]!=0.0 && MathAbs(zz[shift]-g_high[shift])<=(_Point*0.5));
}

bool FindPreviousSwingOfType(const int shift,const bool bullish,int &previous_shift)
{
   previous_shift=-1;
   for(int i=shift+1; i<g_bars; ++i)
   {
      if(bullish && IsSwingLow(i))
      {
         previous_shift=i;
         return(true);
      }
      if(!bullish && IsSwingHigh(i))
      {
         previous_shift=i;
         return(true);
      }
   }
   return(false);
}

bool HasTDIDivergence(const int shift,const bool bullish)
{
   if(shift<1 || shift>=g_bars || g_tdi_rsi[shift]==EMPTY_VALUE)
      return(false);

   int previous_shift=-1;
   if(!FindPreviousSwingOfType(shift,bullish,previous_shift))
      return(false);

   if(g_tdi_rsi[previous_shift]==EMPTY_VALUE)
      return(false);

   if(bullish)
      return(g_low[shift] < g_low[previous_shift] && g_tdi_rsi[shift] > g_tdi_rsi[previous_shift]);

   return(g_high[shift] > g_high[previous_shift] && g_tdi_rsi[shift] < g_tdi_rsi[previous_shift]);
}

bool EntryPointEnabled(const string point_name)
{
   if(EntryPointMode==ENTRY_POINT_BOTH)
      return(true);
   if(EntryPointMode==ENTRY_POINT_B_ONLY)
      return(point_name=="B");
   return(point_name=="C");
}

void EvaluateEntrySignals(const string NamePattern,const string BullBear,const int Depth,const int B,const int C)
{
   bool bullish = (BullBear=="Bullish" || BullBear=="Bull");
   bool bearish = (BullBear=="Bearish" || BullBear=="Bear");
   if(!bullish && !bearish)
      return;

   bool signal_bull = bullish;
   if(EntryPointEnabled("B") && HasTDIDivergence(B,signal_bull))
      CreateEntrySignal(NamePattern,BullBear,"B",Depth,B,signal_bull);

   if(EntryPointEnabled("C") && HasTDIDivergence(C,signal_bull))
      CreateEntrySignal(NamePattern,BullBear,"C",Depth,C,signal_bull);
}

void CreateEntrySignal(const string NamePattern,const string BullBear,const string PointName,const int Depth,const int shift,const bool bullish)
{
   if(shift<0 || shift>=g_bars)
      return;

   string suffix = NamePattern + "_" + BullBear + "_" + PointName + "_" + IntegerToString(Depth) + "_" + IntegerToString(shift) + g_save;
   string arrow_name = "EntryArrow_" + suffix;
   string line_name  = "EntryLine_" + suffix;
   string text_name  = "EntryText_" + suffix;
   double offset     = EntryArrowOffsetPoints * _Point;
   double arrow_price= bullish ? (g_low[shift]-offset) : (g_high[shift]+offset);
   double entry_price= g_close[shift];
   color  entry_color= bullish ? LongEntryColor : ShortEntryColor;
   int    arrow_code = bullish ? 233 : 234;
   ENUM_ARROW_ANCHOR anchor = bullish ? ANCHOR_TOP : ANCHOR_BOTTOM;
   string entry_text = (bullish ? "Long Entry at " : "Short Entry at ") + PointName;

   CreateArrowMarker(arrow_name,g_time[shift],arrow_price,entry_color,arrow_code,anchor);
   if(ShowEntryPriceLine)
      CreateTrend(line_name,g_time[shift],entry_price,(datetime)((long)g_time[shift]+10L*TfSeconds()),entry_price,entry_color,STYLE_DOT,1,false);
   if(ShowEntryLabel)
      CreateTextLabel(text_name,g_time[shift],bullish ? (arrow_price-offset) : (arrow_price+offset),entry_text,entry_color);

   TryMobileEntryAlert(suffix,NamePattern,BullBear,PointName,entry_price,bullish);
}

void TryMobileEntryAlert(const string &suffix,const string &NamePattern,const string &BullBear,const string &PointName,const double entry_price,const bool bullish)
{
   if(!MobileAlerts && !TerminalPopups)
      return;

   string key = suffix + "|" + _Symbol + "|" + EnumToString(_Period);
   if(key == g_last_mobile_entry_key)
      return;
   g_last_mobile_entry_key = key;

   string dir = bullish ? "LONG" : "SHORT";
   string msg = _Symbol + " " + TimeFrame() + ": " + NamePattern + " " + BullBear + " pt " + PointName + " " + dir + " @ " + DoubleToString(entry_price,_Digits);
   if(StringLen(msg) > 255)
      msg = StringSubstr(msg,0,252) + "...";

   if(MobileAlerts)
      SendNotification(msg);
   if(TerminalPopups)
      Alert(msg);
}

bool CreateArrowMarker(const string name,const datetime t1,const double p1,const color clr,const int arrow_code,const ENUM_ARROW_ANCHOR anchor)
{
   DeleteIfExists(name);
   if(!ObjectCreate(0,name,OBJ_ARROW,0,t1,p1))
      return(false);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_ARROWCODE,arrow_code);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   return(true);
}

void RefreshChartMetrics()
{
   g_pixels_x = (int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
   g_pixels_y = (int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
}

int TfSeconds()
{
   int seconds = PeriodSeconds(_Period);
   if(seconds<=0)
      seconds = 60;
   return(seconds);
}

string SaveSuffix()
{
   if(!ExtSave)
      return("");

   string stamp = TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS);
   StringReplace(stamp,".","_");
   StringReplace(stamp,":","_");
   StringReplace(stamp," ","_");
   return("_"+stamp);
}

datetime TimeAtShift(const int shift)
{
   if(shift>=0 && shift<g_bars)
      return(g_time[shift]);

   if(shift>=g_bars)
      return((datetime)((long)g_time[g_bars-1] - (long)(shift-(g_bars-1)) * TfSeconds()));

   return((datetime)((long)g_time[0] + (long)(-shift) * TfSeconds()));
}

datetime MidTime(const datetime t1,const datetime t2)
{
   return((datetime)(((long)t1 + (long)t2) / 2));
}

int SeriesLowest(const double &source[],const int count,const int start)
{
   if(count<=0 || start<0 || start>=g_bars)
      return(start);

   int last = MathMin(g_bars-1,start+count-1);
   int idx  = start;
   double v = source[start];
   for(int i=start+1; i<=last; ++i)
   {
      if(source[i]<v)
      {
         v   = source[i];
         idx = i;
      }
   }
   return(idx);
}

int SeriesHighest(const double &source[],const int count,const int start)
{
   if(count<=0 || start<0 || start>=g_bars)
      return(start);

   int last = MathMin(g_bars-1,start+count-1);
   int idx  = start;
   double v = source[start];
   for(int i=start+1; i<=last; ++i)
   {
      if(source[i]>v)
      {
         v   = source[i];
         idx = i;
      }
   }
   return(idx);
}

void ZZTalex(const int depth)
{
   int    i,j,k,zzbarlow,zzbarhigh,curbar,curbar1,curbar2,EP;
   double curpr;
   int    Mbar[];
   double Mprice[];
   bool   flag,fd;

   for(i=0; i<g_bars; ++i)
      zz[i]=0.0;

   EP        = g_points_to_use;
   zzbarlow  = SeriesLowest(g_low,depth,0);
   zzbarhigh = SeriesHighest(g_high,depth,0);

   if(zzbarlow<zzbarhigh)
   {
      curbar = zzbarlow;
      curpr  = g_low[zzbarlow];
   }
   else if(zzbarlow>zzbarhigh)
   {
      curbar = zzbarhigh;
      curpr  = g_high[zzbarhigh];
   }
   else
   {
      curbar = zzbarlow;
      curpr  = funk1(zzbarlow,depth);
   }

   ArrayResize(Mbar,g_points_to_use);
   ArrayResize(Mprice,g_points_to_use);
   ArrayInitialize(Mbar,-1);
   ArrayInitialize(Mprice,0.0);

   j=0;
   g_endpr     = curpr;
   g_endbar    = curbar;
   Mbar[j]     = curbar;
   Mprice[j]   = curpr;

   EP--;
   flag = (curpr==g_low[curbar]);
   g_fl = flag;

   i = curbar + 1;
   while(EP>0 && i<g_bars)
   {
      if(flag)
      {
         while(i<g_bars)
         {
            curbar1 = SeriesHighest(g_high,depth,i);
            curbar2 = SeriesHighest(g_high,depth,curbar1);
            if(curbar1==curbar2)
            {
               curbar = curbar1;
               curpr  = g_high[curbar];
               flag   = false;
               i      = curbar + 1;
               ++j;
               break;
            }
            i = curbar2;
         }

         if(j>=g_points_to_use)
            break;
         Mbar[j]   = curbar;
         Mprice[j] = curpr;
         EP--;
      }

      if(EP==0 || i>=g_bars)
         break;

      if(!flag)
      {
         while(i<g_bars)
         {
            curbar1 = SeriesLowest(g_low,depth,i);
            curbar2 = SeriesLowest(g_low,depth,curbar1);
            if(curbar1==curbar2)
            {
               curbar = curbar1;
               curpr  = g_low[curbar];
               flag   = true;
               i      = curbar + 1;
               ++j;
               break;
            }
            i = curbar2;
         }

         if(j>=g_points_to_use)
            break;
         Mbar[j]   = curbar;
         Mprice[j] = curpr;
         EP--;
      }
   }

   if(Mbar[0]<0)
      return;

   fd = (Mprice[0]==g_low[Mbar[0]]);
   for(k=0; k<g_points_to_use; ++k)
   {
      if(Mbar[k]<0)
         break;

      if(k==0 && k+1<g_points_to_use && Mbar[k+1]>=0)
      {
         if(fd)
         {
            Mbar[k]   = SeriesLowest(g_low,Mbar[k+1]-Mbar[k],Mbar[k]);
            Mprice[k] = g_low[Mbar[k]];
            g_endbar  = depth;
         }
         else
         {
            Mbar[k]   = SeriesHighest(g_high,Mbar[k+1]-Mbar[k],Mbar[k]);
            Mprice[k] = g_high[Mbar[k]];
            g_endbar  = depth;
         }
      }

      if(k<g_points_to_use-2 && Mbar[k+2]>=0)
      {
         int scan_count = Mbar[k+2]-Mbar[k]-1;
         int scan_start = Mbar[k]+1;
         if(scan_count>0 && scan_start<g_bars)
         {
            if(fd)
            {
               Mbar[k+1]   = SeriesHighest(g_high,scan_count,scan_start);
               Mprice[k+1] = g_high[Mbar[k+1]];
            }
            else
            {
               Mbar[k+1]   = SeriesLowest(g_low,scan_count,scan_start);
               Mprice[k+1] = g_low[Mbar[k+1]];
            }
         }
      }

      fd = !fd;
      zz[Mbar[k]] = Mprice[k];
   }
}

double funk1(const int zzbarlow,const int depth)
{
   double pr;
   int fbarlow  = SeriesLowest(g_low,depth,zzbarlow);
   int fbarhigh = SeriesHighest(g_high,depth,zzbarlow);

   if(fbarlow>fbarhigh)
      pr = g_high[zzbarlow];
   else if(fbarlow<fbarhigh)
      pr = g_low[zzbarlow];
   else
   {
      fbarlow  = SeriesLowest(g_low,2*depth,zzbarlow);
      fbarhigh = SeriesHighest(g_high,2*depth,zzbarlow);
      if(fbarlow>fbarhigh)
         pr = g_high[zzbarlow];
      else if(fbarlow<fbarhigh)
         pr = g_low[zzbarlow];
      else
      {
         fbarlow  = SeriesLowest(g_low,3*depth,zzbarlow);
         fbarhigh = SeriesHighest(g_high,3*depth,zzbarlow);
         if(fbarlow>fbarhigh)
            pr = g_high[zzbarlow];
         else
            pr = g_low[zzbarlow];
      }
   }
   return(pr);
}

string TimeFrame()
{
   switch(_Period)
   {
      case PERIOD_M1:  return("M1");
      case PERIOD_M5:  return("M5");
      case PERIOD_M15: return("M15");
      case PERIOD_M30: return("M30");
      case PERIOD_H1:  return("H1");
      case PERIOD_H4:  return("H4");
      case PERIOD_D1:  return("D1");
      case PERIOD_W1:  return("W1");
      case PERIOD_MN1: return("MN1");
   }
   return(EnumToString(_Period));
}

void GartleyPatternsSearch(const int X,const int A,const int B,const int C,const int D,const int Depth)
{
   if(g_last_gartley_x==X && g_last_gartley_a==A && g_last_gartley_b==B && g_last_gartley_c==C && g_last_gartley_d==D)
      return;
   g_last_gartley_x=X; g_last_gartley_a=A; g_last_gartley_b=B; g_last_gartley_c=C; g_last_gartley_d=D;

   double R0382=0.382,R0618=0.618,R0786=0.786,R0886=0.886,R1128=1.128,R1272=1.272,R1618=1.618,R2236=2.236,R2618=2.618,R3618=3.618;
   double retXD=0.0,retXB=0.0,retBD=0.0,retAC=0.0,minret=1.0-ExtDopusk,maxret=1.0+ExtDopusk;
   string BullBear="",NamePattern="",MinMax="";

   if(!FuturePattern)
   {
      if(zz[D]<zz[B] && zz[C]>zz[B] && zz[C]<zz[A] && zz[B]>zz[X]) { BullBear="Bullish"; MinMax="Min"; }
      if(zz[D]>zz[B] && zz[C]<zz[B] && zz[C]>zz[A] && zz[B]<zz[X]) { BullBear="Bearish"; MinMax="Max"; }

      if(BullBear!="")
      {
         retXB=(zz[A]-zz[B])/(zz[A]-zz[X]+0.000001);
         retAC=(zz[C]-zz[B])/(zz[A]-zz[B]+0.000001);
         retBD=(zz[C]-zz[D])/(zz[C]-zz[B]+0.000001);
         retXD=(zz[A]-zz[D])/(zz[A]-zz[X]+0.000001);

         if((retXB>=R0382*minret) && (retXB<=R0618*maxret) && (retAC>=R0382*minret) && (retAC<=R0886*maxret) && (retBD>=R1128*minret) && (retBD<=R2236*maxret) && (retXD>=R0618*minret) && (retXD<=R0786*maxret))
            NamePattern="Gartley";
         else if((retXB>=R0618*minret) && (retXB<=R0886*maxret) && (retAC>=R0382*minret) && (retAC<=R0886*maxret) && (retBD>=R1272*minret) && (retBD<=R2618*maxret) && (retXD>=R1272*minret) && (retXD<=R1618*maxret))
            NamePattern="Butterfly";
         else if((retXB>=R0382*minret) && (retXB<=R0886*maxret) && (retAC>=R0382*minret) && (retAC<=R0886*maxret) && (retBD>=R1618*minret) && (retBD<=R3618*maxret) && (retXD>=R1618*minret) && (retXD<=R1618*maxret))
            NamePattern="Crab";
         else if((retXB>=R0382*minret) && (retXB<=R0618*maxret) && (retAC>=R0382*minret) && (retAC<=R0886*maxret) && (retBD>=R1272*minret) && (retBD<=R2618*maxret) && (retXD>=R0886*minret) && (retXD<=R0886*maxret))
            NamePattern="Bat";
      }

      if(NamePattern!="")
      {
         CreateRealPattern(NamePattern,BullBear,Depth,X,A,B,C,D,retXB,retAC,retBD,retXD,minret,maxret);
         TargetAndFibo(NamePattern,BullBear,MinMax,maxret,Depth,X,A,B,C,D);
      }
   }
   else
   {
      int X4=A,A4=B,B4=C,C4=D;
      double retBDminD,retBDmaxD,retXDminD,retXDmaxD,minD,maxD,maxAC;

      if(zz[B4]<zz[A4] && zz[B4]>zz[X4] && zz[C4]<zz[A4] && zz[C4]>zz[B4]) { BullBear="Bullish"; MinMax="Max"; }
      if(zz[B4]>zz[A4] && zz[B4]<zz[X4] && zz[C4]>zz[A4] && zz[C4]<zz[B4]) { BullBear="Bearish"; MinMax="Min"; }

      if(BullBear!="")
      {
         retXB=(zz[A4]-zz[B4])/(zz[A4]-zz[X4]+0.000001);
         retAC=(zz[C4]-zz[B4])/(zz[A4]-zz[B4]+0.000001);

         if((retXB>=R0382*minret) && (retXB<=R0618*maxret) && (retAC>=R0382*minret) && (retAC<=R0886*maxret))
         {
            NamePattern="Gartley";
            retBDminD=zz[C4]-R1128*minret*(zz[C4]-zz[B4]);
            retBDmaxD=zz[C4]-R2236*maxret*(zz[C4]-zz[B4]);
            retXDminD=zz[A4]-R0618*minret*(zz[A4]-zz[X4]);
            retXDmaxD=zz[A4]-R0786*maxret*(zz[A4]-zz[X4]);
            maxAC=0.886*maxret*(zz[A4]-zz[B4])+zz[B4];
            if(BullBear=="Bullish") { minD=MathMin(retBDminD,retXDminD); maxD=MathMax(retBDmaxD,retXDmaxD); }
            else                    { minD=MathMax(retBDminD,retXDminD); maxD=MathMin(retBDmaxD,retXDmaxD); }
            CreateFuturePattern(X4,A4,B4,C4,Depth,minD,maxD,maxAC,retXB,retAC,BullBear,NamePattern,MinMax);
         }
         else if((retXB>=R0618*minret) && (retXB<=R0886*maxret) && (retAC>=R0382*minret) && (retAC<=R0886*maxret))
         {
            NamePattern="Butterfly";
            retBDminD=zz[C4]-R1272*minret*(zz[C4]-zz[B4]);
            retBDmaxD=zz[C4]-R2618*maxret*(zz[C4]-zz[B4]);
            retXDminD=zz[A4]-R1272*minret*(zz[A4]-zz[X4]);
            retXDmaxD=zz[A4]-R1618*maxret*(zz[A4]-zz[X4]);
            maxAC=0.886*maxret*(zz[A4]-zz[B4])+zz[B4];
            if(BullBear=="Bullish") { minD=MathMin(retBDminD,retXDminD); maxD=MathMax(retBDmaxD,retXDmaxD); }
            else                    { minD=MathMax(retBDminD,retXDminD); maxD=MathMin(retBDmaxD,retXDmaxD); }
            CreateFuturePattern(X4,A4,B4,C4,Depth,minD,maxD,maxAC,retXB,retAC,BullBear,NamePattern,MinMax);
         }
         else if((retXB>=R0382*minret) && (retXB<=R0886*maxret) && (retAC>=R0382*minret) && (retAC<=R0886*maxret))
         {
            NamePattern="Crab";
            retBDminD=zz[C4]-R1618*minret*(zz[C4]-zz[B4]);
            retBDmaxD=zz[C4]-R3618*maxret*(zz[C4]-zz[B4]);
            retXDminD=zz[A4]-R1618*minret*(zz[A4]-zz[X4]);
            retXDmaxD=zz[A4]-R1618*maxret*(zz[A4]-zz[X4]);
            maxAC=0.886*maxret*(zz[A4]-zz[B4])+zz[B4];
            if(BullBear=="Bullish") { minD=MathMin(retBDminD,retXDminD); maxD=MathMax(retBDmaxD,retXDmaxD); }
            else                    { minD=MathMax(retBDminD,retXDminD); maxD=MathMin(retBDmaxD,retXDmaxD); }
            CreateFuturePattern(X4,A4,B4,C4,Depth,minD,maxD,maxAC,retXB,retAC,BullBear,NamePattern,MinMax);
         }
         else if((retXB>=R0382*minret) && (retXB<=R0618*maxret) && (retAC>=R0382*minret) && (retAC<=R0886*maxret))
         {
            NamePattern="Bat";
            retBDminD=zz[C4]-R1272*minret*(zz[C4]-zz[B4]);
            retBDmaxD=zz[C4]-R2618*maxret*(zz[C4]-zz[B4]);
            retXDminD=zz[A4]-R0886*minret*(zz[A4]-zz[X4]);
            retXDmaxD=zz[A4]-R0886*maxret*(zz[A4]-zz[X4]);
            maxAC=0.886*maxret*(zz[A4]-zz[B4])+zz[B4];
            if(BullBear=="Bullish") { minD=MathMin(retBDminD,retXDminD); maxD=MathMax(retBDmaxD,retXDmaxD); }
            else                    { minD=MathMax(retBDminD,retXDminD); maxD=MathMin(retBDmaxD,retXDmaxD); }
            CreateFuturePattern(X4,A4,B4,C4,Depth,minD,maxD,maxAC,retXB,retAC,BullBear,NamePattern,MinMax);
         }
      }
   }
}

void Patterns50Search(const int X,const int A,const int B,const int C,const int D,const int Depth)
{
   if(g_last_50_x==X && g_last_50_a==A && g_last_50_b==B && g_last_50_c==C && g_last_50_d==D)
      return;
   g_last_50_x=X; g_last_50_a=A; g_last_50_b=B; g_last_50_c=C; g_last_50_d=D;

   double R0500=0.500,R1128=1.128,R1618=1.618,R2236=2.236;
   double retXD=0.0,retXB=0.0,retBD=0.0,retAC=0.0,minret=1.0-ExtDopusk,maxret=1.0+ExtDopusk;
   string BullBear="",NamePattern="",MinMax="";

   if(!FuturePattern)
   {
      if(zz[X]>zz[B] && zz[X]<zz[A] && zz[D]>zz[B] && zz[D]<zz[C] && zz[A]<zz[C]) { BullBear="Bullish"; MinMax="Min"; }
      if(zz[X]<zz[B] && zz[X]>zz[A] && zz[D]<zz[B] && zz[D]>zz[C] && zz[A]>zz[C]) { BullBear="Bearish"; MinMax="Max"; }

      if(BullBear!="")
      {
         retXB=(zz[A]-zz[B])/(zz[A]-zz[X]+0.000001);
         retAC=(zz[C]-zz[B])/(zz[A]-zz[B]+0.000001);
         retBD=(zz[C]-zz[D])/(zz[C]-zz[B]+0.000001);
         if((retXB>=R1128*minret) && (retXB<=R1618*maxret) && (retAC>=R1618*minret) && (retAC<=R2236*maxret) && (retBD>=R0500*minret) && (retBD<=R0500*maxret))
            NamePattern="Pattern_5-0";
      }

      if(NamePattern!="")
      {
         CreateRealPattern(NamePattern,BullBear,Depth,X,A,B,C,D,retXB,retAC,retBD,retXD,minret,maxret);
         TargetAndFibo(NamePattern,BullBear,MinMax,maxret,Depth,X,A,B,C,D);
      }
   }
   else
   {
      int X4=A,A4=B,B4=C,C4=D;
      double retBDminD,retBDmaxD,minD,maxD,maxAC;

      if(zz[X4]<zz[A4] && zz[X4]>zz[B4] && zz[A4]<zz[C4]) { BullBear="Bullish"; MinMax="Max"; }
      if(zz[X4]>zz[A4] && zz[X4]<zz[B4] && zz[A4]>zz[C4]) { BullBear="Bearish"; MinMax="Min"; }

      if(BullBear!="")
      {
         retXB=(zz[A4]-zz[B4])/(zz[A4]-zz[X4]+0.000001);
         retAC=(zz[C4]-zz[B4])/(zz[A4]-zz[B4]+0.000001);

         if((retXB>=R1128*minret) && (retXB<=R1618*maxret) && (retAC>=R1618*minret) && (retAC<=R2236*maxret))
         {
            NamePattern="Pattern_5-0";
            retBDminD=zz[C4]-R0500*minret*(zz[C4]-zz[B4]);
            retBDmaxD=zz[C4]-R0500*maxret*(zz[C4]-zz[B4]);
            maxAC=2.236*maxret*(zz[A4]-zz[B4])+zz[B4];
            if(BullBear=="Bearish") { minD=retBDmaxD; maxD=retBDminD; }
            else                    { minD=retBDminD; maxD=retBDmaxD; }
            CreateFuturePattern(X4,A4,B4,C4,Depth,minD,maxD,maxAC,retXB,retAC,BullBear,NamePattern,MinMax);
         }
      }
   }
}

void ABCDSearch(const int A,const int B,const int C,const int D,const int Depth)
{
   if(g_last_abcd_a==A && g_last_abcd_b==B && g_last_abcd_c==C && g_last_abcd_d==D)
      return;
   g_last_abcd_a=A; g_last_abcd_b=B; g_last_abcd_c=C; g_last_abcd_d=D;

   double R0618=0.618,R0786=0.786,R1272=1.272,R1618=1.618;
   double retBD=0.0,retAC=0.0,retXB=0.0,retXD=0.0,minret=1.0-ExtDopusk,maxret=1.0+ExtDopusk;
   string BullBear="",NamePattern="",MinMax="";
   int X=0;

   if(!FuturePattern)
   {
      double abcd_ratio = MathAbs(zz[A]-zz[B]) / (MathAbs(zz[C]-zz[D]) + 0.000001);
      double time_ratio = (A-C) / (1.0 * ((B-D)==0 ? 1 : (B-D)));
      if(abcd_ratio<=maxret && abcd_ratio>=minret && time_ratio<=1.0+TimeDopusk && time_ratio>=1.0-TimeDopusk)
      {
         if(zz[A]>zz[C] && zz[B]<zz[C] && zz[B]>zz[D]) { BullBear="Bullish"; MinMax="Min"; }
         if(zz[A]<zz[C] && zz[B]>zz[C] && zz[B]<zz[D]) { BullBear="Bearish"; MinMax="Max"; }

         if(BullBear!="")
         {
            retAC=(zz[C]-zz[B])/(zz[A]-zz[B]+0.000001);
            retBD=(zz[C]-zz[D])/(zz[C]-zz[B]+0.000001);
            if((retAC>=R0618*minret) && (retAC<=R0786*maxret) && (retBD>=R1272*minret) && (retBD<=R1618*maxret))
               NamePattern="AB=CD";
         }

         if(NamePattern!="")
         {
            CreateRealPattern(NamePattern,BullBear,Depth,X,A,B,C,D,retXB,retAC,retBD,retXD,minret,maxret);
            TargetAndFibo(NamePattern,BullBear,MinMax,maxret,Depth,X,A,B,C,D);
         }
      }
   }
   else
   {
      int X4=0,A4=B,B4=C,C4=D;
      double retBDminD,retBDmaxD,minD,maxD,maxAC;

      if(zz[A4]>zz[C4] && zz[C4]>zz[B4]) { BullBear="Bullish"; MinMax="Max"; }
      if(zz[A4]<zz[C4] && zz[C4]<zz[B4]) { BullBear="Bearish"; MinMax="Min"; }

      if(BullBear!="")
      {
         retAC=(zz[C4]-zz[B4])/(zz[A4]-zz[B4]+0.000001);
         if((retAC>=R0618*minret) && (retAC<=R0786*maxret))
         {
            NamePattern="AB=CD";
            retBDminD=zz[C4]-minret*(zz[A4]-zz[B4]);
            retBDmaxD=zz[C4]-maxret*(zz[A4]-zz[B4]);
            maxAC=0.786*maxret*(zz[A4]-zz[B4])+zz[B4];
            if(BullBear=="Bearish") { minD=retBDmaxD; maxD=retBDminD; }
            else                    { minD=retBDminD; maxD=retBDmaxD; }
            CreateFuturePattern(X4,A4,B4,C4,Depth,minD,maxD,maxAC,retXB,retAC,BullBear,NamePattern,MinMax);
         }
      }
   }
}

void WolfWavesSearch(int P1,int P2,int P3,int P4,int P5,const int Depth)
{
   if(g_last_ww_p1==P1 && g_last_ww_p2==P2 && g_last_ww_p3==P3 && g_last_ww_p4==P4 && g_last_ww_p5==P5)
      return;
   g_last_ww_p1=P1; g_last_ww_p2=P2; g_last_ww_p3=P3; g_last_ww_p4=P4; g_last_ww_p5=P5;

   datetime t1,t2,t3,t4,t5,t6,t7,t8,t9;
   double p1,p2,p3,p4,p5,p6,p7,p8,p9;
   double condition1,condition2;
   string BullBear="",NamePattern="";

   if(!FuturePattern)
   {
      double r13_35 = (P3-P5)==0 ? 0.0 : (P1-P3)/(1.0*(P3-P5));
      double r13_24 = (P2-P4)==0 ? 0.0 : (P1-P3)/(1.0*(P2-P4));
      double r24_35 = (P3-P5)==0 ? 0.0 : (P2-P4)/(1.0*(P3-P5));

      if(zz[P1]<zz[P2] && zz[P1]>zz[P3] && zz[P4]<zz[P2] && zz[P4]>zz[P1] && zz[P5]<zz[P3] &&
         r13_35<=1.0+TimeDopusk && r13_35>=1.0-TimeDopusk &&
         r13_24<=1.0+TimeDopusk && r13_24>=1.0-TimeDopusk &&
         r24_35<=1.0+TimeDopusk && r24_35>=1.0-TimeDopusk)
         BullBear="Bullish";

      if(zz[P1]>zz[P2] && zz[P1]<zz[P3] && zz[P4]>zz[P2] && zz[P4]<zz[P1] && zz[P5]>zz[P3] &&
         r13_35<=1.0+TimeDopusk && r13_35>=1.0-TimeDopusk &&
         r13_24<=1.0+TimeDopusk && r13_24>=1.0-TimeDopusk &&
         r24_35<=1.0+TimeDopusk && r24_35>=1.0-TimeDopusk)
         BullBear="Bearish";

      if(BullBear!="")
      {
         t1=g_time[P1]; p1=zz[P1];
         t2=g_time[P2]; p2=zz[P2];
         t3=g_time[P3]; p3=zz[P3];
         t4=g_time[P4]; p4=zz[P4];
         t5=g_time[P5]; p5=zz[P5];
         t6=g_time[P5]; p6=zz[P3]-NormalizeDouble(((zz[P1]-zz[P3])/(P1-P3))*(P3-P5),_Digits);
         t7=g_time[P5]; p7=zz[P3]-NormalizeDouble(((zz[P2]-zz[P4])/(P2-P4))*(P3-P5),_Digits);
         t8=TimeAtShift(-(2*P4-P1)); p8=2*zz[P4]-zz[P1];
         t9=(datetime)((long)t8 + (long)(P1-P3) * TfSeconds()); p9=p8-(zz[P1]-zz[P3]);

         if(p7<p6) { condition1=p6; condition2=p7; }
         else      { condition1=p7; condition2=p6; }

         if(zz[P5]<=condition1 && zz[P5]>=condition2)
         {
            NamePattern="WolfeWaves";
            WolfWavesDraw(NamePattern,BullBear,Depth,t1,p1,t2,p2,t3,p3,t4,p4,t5,p5,t6,p6,t7,p7,t8,p8,t9,p9);
         }
      }
   }
   else
   {
      P1=P2; P2=P3; P3=P4; P4=P5; P5=0;
      double r13_24 = (P2-P4)==0 ? 0.0 : (P1-P3)/(1.0*(P2-P4));

      if(zz[P1]<zz[P2] && zz[P1]>zz[P3] && zz[P4]<zz[P2] && zz[P4]>zz[P1] && r13_24<=1.0+TimeDopusk && r13_24>=1.0-TimeDopusk)
         BullBear="Bull";
      if(zz[P1]>zz[P2] && zz[P1]<zz[P3] && zz[P4]>zz[P2] && zz[P4]<zz[P1] && r13_24<=1.0+TimeDopusk && r13_24>=1.0-TimeDopusk)
         BullBear="Bear";

      if(BullBear!="")
      {
         t1=g_time[P1]; p1=zz[P1];
         t2=g_time[P2]; p2=zz[P2];
         t3=g_time[P3]; p3=zz[P3];
         t4=g_time[P4]; p4=zz[P4];
         t5=TimeAtShift(2*P3-P1); p5=2*p3-p1;
         if(p4>=p5)
            return;
         t6=t5; p6=p5;
         t7=t5; p7=zz[P3]-NormalizeDouble(((zz[P2]-zz[P4])/(P2-P4))*(P1-P3),_Digits);
         t8=TimeAtShift(-(2*P4-P1)); p8=2*zz[P4]-zz[P1];
         t9=(datetime)((long)t8 + (long)(P1-P3) * TfSeconds()); p9=p8-(zz[P1]-zz[P3]);

         NamePattern="WolfeWaves";
         WolfWavesDraw(NamePattern,BullBear,Depth,t1,p1,t2,p2,t3,p3,t4,p4,t5,p5,t6,p6,t7,p7,t8,p8,t9,p9);
      }
   }
}

void CorrectObject()
{
   int total = ObjectsTotal(0,-1,-1);
   for(int i=0; i<total; ++i)
   {
      string name1 = ObjectName(0,i,-1,-1);
      if(!IsTriangleObject(name1))
         continue;

      datetime t11=(datetime)ObjectGetInteger(0,name1,OBJPROP_TIME,0);
      datetime t12=(datetime)ObjectGetInteger(0,name1,OBJPROP_TIME,1);
      datetime t13=(datetime)ObjectGetInteger(0,name1,OBJPROP_TIME,2);
      double   p11=ObjectGetDouble(0,name1,OBJPROP_PRICE,0);
      double   p12=ObjectGetDouble(0,name1,OBJPROP_PRICE,1);
      double   p13=ObjectGetDouble(0,name1,OBJPROP_PRICE,2);

      for(int j=i+1; j<total; ++j)
      {
         string name2 = ObjectName(0,j,-1,-1);
         if(!IsTriangleObject(name2))
            continue;

         if(t11==(datetime)ObjectGetInteger(0,name2,OBJPROP_TIME,0) &&
            t12==(datetime)ObjectGetInteger(0,name2,OBJPROP_TIME,1) &&
            t13==(datetime)ObjectGetInteger(0,name2,OBJPROP_TIME,2) &&
            p11==ObjectGetDouble(0,name2,OBJPROP_PRICE,0) &&
            p12==ObjectGetDouble(0,name2,OBJPROP_PRICE,1) &&
            p13==ObjectGetDouble(0,name2,OBJPROP_PRICE,2))
         {
            DeleteIfExists(name2);
         }
      }
   }
}

void Commentarii()
{
   string seen[9];
   int found=0;
   int total=ObjectsTotal(0,-1,-1);

   for(int i=0; i<total && found<9; ++i)
   {
      string name=ObjectName(0,i,-1,-1);
      if(!IsTriangleObject(name))
         continue;

      string label = TriangleLabel(name);
      if(label=="")
         continue;

      bool exists=false;
      for(int j=0; j<found; ++j)
      {
         if(seen[j]==label)
         {
            exists=true;
            break;
         }
      }
      if(!exists)
         seen[found++] = label;
   }

   string text = "Search patterns";
   for(int k=0; k<found; ++k)
      text += "\n" + seen[k];
   Comment(text);
}

string ExtRet(const double enterret,const double minret,const double maxret)
{
   double levels[14]={0.382,0.5,0.618,0.707,0.786,0.886,1.128,1.236,1.272,1.414,1.618,2.236,2.618,3.618};
   for(int i=0; i<ArraySize(levels); ++i)
   {
      double level=levels[i];
      if(enterret>=level*minret && enterret<=level*maxret)
      {
         double ret=(enterret/level-1.0)*100.0;
         string sign=(ret>=0.0 ? "+" : "-");
         return(" ("+DoubleToString(level,3)+sign+DoubleToString(MathAbs(ret),2)+"%)");
      }
   }
   return(" (n/a)");
}

void TargetAndFibo(const string NamePattern,const string BullBear,const string MinMax,const double maxret,const int Depth,const int X,const int A,const int B,const int C,const int D)
{
   double PriceD=0.0,PriceD_XD=0.0,PriceD_BD=0.0,TextMove=0.0;
   if(BullBear=="Bearish")
      TextMove=TextEdit();

   if(NamePattern=="Pattern_5-0") PriceD=zz[C]-0.5*maxret*(zz[C]-zz[B]);
   if(NamePattern=="AB=CD")       PriceD=zz[C]-maxret*(zz[A]-zz[B]);
   if(NamePattern=="Gartley")     { PriceD_XD=zz[A]-0.786*maxret*(zz[A]-zz[X]); PriceD_BD=zz[C]-2.236*maxret*(zz[C]-zz[B]); }
   if(NamePattern=="Butterfly")   { PriceD_XD=zz[A]-1.618*maxret*(zz[A]-zz[X]); PriceD_BD=zz[C]-2.618*maxret*(zz[C]-zz[B]); }
   if(NamePattern=="Crab")        { PriceD_XD=zz[A]-1.618*maxret*(zz[A]-zz[X]); PriceD_BD=zz[C]-3.618*maxret*(zz[C]-zz[B]); }
   if(NamePattern=="Bat")         { PriceD_XD=zz[A]-0.886*maxret*(zz[A]-zz[X]); PriceD_BD=zz[C]-2.618*maxret*(zz[C]-zz[B]); }

   if(NamePattern=="Gartley" || NamePattern=="Butterfly" || NamePattern=="Crab" || NamePattern=="Bat")
      PriceD=((BullBear=="Bullish" && PriceD_XD<PriceD_BD) || (BullBear=="Bearish" && PriceD_XD>PriceD_BD)) ? PriceD_BD : PriceD_XD;

   datetime timeD = TimeAtShift(D-10);
   string suffix = NamePattern + IntegerToString(Depth) + g_save;
   DeleteIfExists("RealTargetD_"     + suffix);
   DeleteIfExists("RealTextTargetD_" + suffix);
   DeleteIfExists("RealFiboTarget_"  + suffix);

   CreateTrend("RealTargetD_" + suffix,g_time[D],PriceD,timeD,PriceD,ExtColorRet,STYLE_SOLID,1,false);
   CreateTextLabel("RealTextTargetD_" + suffix,g_time[D],PriceD+TextMove,NamePattern+MinMax+"PriceD="+DoubleToString(PriceD,_Digits),ExtColorRet);
   CreateFibo("RealFiboTarget_" + suffix,g_time[C],zz[C],g_time[D],zz[D],NamePattern);
}

void CreateFuturePattern(const int X4,const int A4,const int B4,const int C4,const int Depth,const double minD,const double maxD,const double maxAC,const double retXB,const double retAC,const string BullBear,const string NamePattern,const string MinMax)
{
   datetime Tm=TimeAtShift(2*B4-X4);
   double minret=1.0-ExtDopusk,maxret=1.0+ExtDopusk,TextMove=0.0;
   string suffix = NamePattern + IntegerToString(Depth) + g_save;
   string label  = PatternLabel(NamePattern,BullBear,Depth);

   if(NamePattern=="Pattern_5-0" || NamePattern=="AB=CD")
   {
      DeleteIfExists("Future3_" + suffix);
      CreateTriangle("Future3_" + suffix,g_time[A4],zz[A4],g_time[B4],zz[B4],g_time[C4],zz[C4],ExtColorGartley,label);
      Tm=TimeAtShift(C4-(A4-B4));
   }

   if(NamePattern!="AB=CD")
   {
      DeleteIfExists("Future1_" + suffix);
      CreateTriangle("Future1_" + suffix,g_time[X4],zz[X4],g_time[A4],zz[A4],g_time[B4],zz[B4],ExtColorGartley,label);
   }

   DeleteIfExists("Future2_" + suffix);
   CreateTriangle("Future2_" + suffix,g_time[B4],zz[B4],g_time[C4],zz[C4],Tm,(minD+maxD)/2.0,ExtColorGartley,label);

   if(NamePattern!="WolfeWaves" && BullBear=="Bullish")
      TextMove=TextEdit();
   DeleteIfExists("FutureTargetC_" + suffix);
   DeleteIfExists("FutureTextTargetC_" + suffix);
   CreateTrend("FutureTargetC_" + suffix,g_time[C4],maxAC,(datetime)((long)g_time[C4]+10L*TfSeconds()),maxAC,ExtColorRet,STYLE_SOLID,1,false);
   CreateTextLabel("FutureTextTargetC_" + suffix,g_time[C4],maxAC+TextMove,NamePattern+MinMax+"PriceC="+DoubleToString(maxAC,_Digits),ExtColorRet);

   DeleteIfExists("FutureMinTargetD_" + suffix);
   DeleteIfExists("FutureTextMinTargetD_" + suffix);
   CreateTrend("FutureMinTargetD_" + suffix,Tm,minD,(datetime)((long)Tm+10L*TfSeconds()),minD,ExtColorRet,STYLE_SOLID,1,false);
   CreateTextLabel("FutureTextMinTargetD_" + suffix,Tm,minD+TextMove,NamePattern+"MinPriceD="+DoubleToString(minD,_Digits),ExtColorRet);

   TextMove=0.0;
   if(NamePattern!="WolfeWaves" && BullBear=="Bearish")
      TextMove=TextEdit();
   DeleteIfExists("FutureMaxTargetD_" + suffix);
   DeleteIfExists("FutureTextMaxTargetD_" + suffix);
   CreateTrend("FutureMaxTargetD_" + suffix,Tm,maxD,(datetime)((long)Tm+10L*TfSeconds()),maxD,ExtColorRet,STYLE_SOLID,1,false);
   CreateTextLabel("FutureTextMaxTargetD_" + suffix,Tm,maxD+TextMove,NamePattern+"MaxPriceD="+DoubleToString(maxD,_Digits),ExtColorRet);

   string RXB=DoubleToString(retXB,3)+ExtRet(retXB,minret,maxret);
   string RAC=DoubleToString(retAC,3)+ExtRet(retAC,minret,maxret);

   if(NamePattern!="AB=CD")
   {
      TextMove=0.0;
      if(NamePattern!="WolfeWaves" && BullBear=="Bearish")
         TextMove=TextEdit();
      DeleteIfExists("FutureRetXB_" + suffix);
      DeleteIfExists("FutureTextRetXB_" + suffix);
      CreateTrend("FutureRetXB_" + suffix,g_time[X4],zz[X4],g_time[B4],zz[B4],ExtColorRet,STYLE_DOT,1,false);
      CreateTextLabel("FutureTextRetXB_" + suffix,MidTime(g_time[X4],g_time[B4]),(zz[X4]+zz[B4])/2.0+TextMove,RXB,ExtColorRet,AngleEdit(X4,zz[X4],B4,zz[B4]));
   }

   TextMove=0.0;
   if(NamePattern!="WolfeWaves" && BullBear=="Bullish")
      TextMove=TextEdit();
   DeleteIfExists("FutureRetAC_" + suffix);
   DeleteIfExists("FutureTextRetAC_" + suffix);
   CreateTrend("FutureRetAC_" + suffix,g_time[A4],zz[A4],g_time[C4],zz[C4],ExtColorRet,STYLE_DOT,1,false);
   CreateTextLabel("FutureTextRetAC_" + suffix,MidTime(g_time[A4],g_time[C4]),(zz[A4]+zz[C4])/2.0+TextMove,RAC,ExtColorRet,AngleEdit(A4,zz[A4],C4,zz[C4]));

   EvaluateEntrySignals(NamePattern,BullBear,Depth,B4,C4);
}

void CreateRealPattern(const string NamePattern,const string BullBear,const int Depth,const int X,const int A,const int B,const int C,const int D,const double retXB,const double retAC,const double retBD,const double retXD,const double minret,const double maxret)
{
   double TextMove=0.0;
   int XB=(int)MathCeil((X+B)/2.0);
   int AC=(int)MathCeil((A+C)/2.0);
   int BD=(int)MathCeil((B+D)/2.0);
   int XD=(int)MathCeil((X+D)/2.0);
   string suffix=NamePattern + IntegerToString(Depth) + g_save;
   string label =PatternLabel(NamePattern,BullBear,Depth);
   string RXB=DoubleToString(retXB,3)+ExtRet(retXB,minret,maxret);
   string RAC=DoubleToString(retAC,3)+ExtRet(retAC,minret,maxret);
   string RBD=DoubleToString(retBD,3)+ExtRet(retBD,minret,maxret);
   string RXD=DoubleToString(retXD,3)+ExtRet(retXD,minret,maxret);

   if(NamePattern!="AB=CD")
   {
      DeleteIfExists("Real1_" + suffix);
      CreateTriangle("Real1_" + suffix,g_time[X],zz[X],g_time[A],zz[A],g_time[B],zz[B],ExtColorGartley,label);
   }

   DeleteIfExists("Real2_" + suffix);
   CreateTriangle("Real2_" + suffix,g_time[B],zz[B],g_time[C],zz[C],g_time[D],zz[D],ExtColorGartley,label);

   if(NamePattern=="Pattern_5-0" || NamePattern=="AB=CD")
   {
      DeleteIfExists("Real3_" + suffix);
      CreateTriangle("Real3_" + suffix,g_time[A],zz[A],g_time[B],zz[B],g_time[C],zz[C],ExtColorGartley,label);
   }

   if(NamePattern!="WolfeWaves" && BullBear=="Bullish")
      TextMove=TextEdit();
   DeleteIfExists("RealRetAC_" + suffix);
   DeleteIfExists("RealTextRetAC_" + suffix);
   CreateTrend("RealRetAC_" + suffix,g_time[A],zz[A],g_time[C],zz[C],ExtColorRet,STYLE_DOT,1,false);
   CreateTextLabel("RealTextRetAC_" + suffix,g_time[AC],(zz[A]+zz[C])/2.0+TextMove,RAC,ExtColorRet,AngleEdit(A,zz[A],C,zz[C]));

   TextMove=0.0;
   if(NamePattern!="WolfeWaves" && BullBear=="Bearish")
      TextMove=TextEdit();
   if(NamePattern!="AB=CD")
   {
      DeleteIfExists("RealRetXB_" + suffix);
      DeleteIfExists("RealTextRetXB_" + suffix);
      CreateTrend("RealRetXB_" + suffix,g_time[X],zz[X],g_time[B],zz[B],ExtColorRet,STYLE_DOT,1,false);
      CreateTextLabel("RealTextRetXB_" + suffix,g_time[XB],(zz[X]+zz[B])/2.0+TextMove,RXB,ExtColorRet,AngleEdit(X,zz[X],B,zz[B]));
   }

   DeleteIfExists("RealRetBD_" + suffix);
   DeleteIfExists("RealTextRetBD_" + suffix);
   CreateTrend("RealRetBD_" + suffix,g_time[B],zz[B],g_time[D],zz[D],ExtColorRet,STYLE_DOT,1,false);
   CreateTextLabel("RealTextRetBD_" + suffix,g_time[BD],(zz[B]+zz[D])/2.0+TextMove,RBD,ExtColorRet,AngleEdit(B,zz[B],D,zz[D]));

   if(NamePattern!="Pattern_5-0" && NamePattern!="AB=CD")
   {
      DeleteIfExists("RealRetXD_" + suffix);
      DeleteIfExists("RealTextRetXD_" + suffix);
      CreateTrend("RealRetXD_" + suffix,g_time[X],zz[X],g_time[D],zz[D],ExtColorRet,STYLE_DOT,1,false);
      CreateTextLabel("RealTextRetXD_" + suffix,g_time[XD],(zz[X]+zz[D])/2.0+TextMove,RXD,ExtColorRet,AngleEdit(X,zz[X],D,zz[D]));
   }

   TextMove=0.0;
   if(NamePattern!="AB=CD")
      CreateTrend("RealLineXA_" + suffix,g_time[X],zz[X],g_time[A],zz[A],clrSkyBlue,STYLE_DOT,2,false);
   CreateTrend("RealLineAB_" + suffix,g_time[A],zz[A],g_time[B],zz[B],clrSkyBlue,STYLE_DOT,2,false);
   CreateTrend("RealLineBC_" + suffix,g_time[B],zz[B],g_time[C],zz[C],clrSkyBlue,STYLE_DOT,2,false);
   CreateTrend("RealLineCD_" + suffix,g_time[C],zz[C],g_time[D],zz[D],clrSkyBlue,STYLE_DOT,2,false);

   EvaluateEntrySignals(NamePattern,BullBear,Depth,B,C);
}

void WolfWavesDraw(const string NamePattern,const string BullBear,const int Depth,
                   const datetime t1,const double p1,const datetime t2,const double p2,const datetime t3,const double p3,const datetime t4,const double p4,const datetime t5,const double p5,const datetime t6,const double p6,const datetime t7,const double p7,const datetime t8,const double p8,const datetime t9,const double p9)
{
   string suffix=NamePattern + IntegerToString(Depth) + g_save;
   string label =PatternLabel(NamePattern,BullBear,Depth);

   CreateTrend("RealRetXB_" + suffix,t1,p1,t6,p6,clrBlue,STYLE_SOLID,1,false);
   CreateTrend("RealRetXD_" + suffix,t1,p1,t8,p8,clrRed,STYLE_SOLID,1,false);
   CreateTrend("RealRetAC_" + suffix,t2,p2,t4,p4,clrBlue,STYLE_SOLID,1,false);

   if(SweetZoneStart)
      CreateTriangle("Real1_" + suffix,t3,p3,t6,p6,t7,p7,SZScolor,label);

   if(SweetZoneEnd)
   {
      CreateTriangle("Real2_" + suffix,t1,p1,t3,p3,t8,p8,SZEcolor,label);
      CreateTriangle("Real3_" + suffix,t3,p3,t8,p8,t9,p9,SZEcolor,label);
   }
}

double TextEdit()
{
   double maxPrice = ChartGetDouble(0,CHART_PRICE_MAX,0);
   double minPrice = ChartGetDouble(0,CHART_PRICE_MIN,0);
   double range    = maxPrice - minPrice;
   if(range<=0.0 || g_pixels_y<=0)
      return(0.0);

   double pixelsOfPips = g_pixels_y / range;
   return(19.0 / pixelsOfPips);
}

double AngleEdit(const int BarPoint1,const double PricePoint1,const int BarPoint2,const double PricePoint2)
{
   double maxPrice = ChartGetDouble(0,CHART_PRICE_MAX,0);
   double minPrice = ChartGetDouble(0,CHART_PRICE_MIN,0);
   int    bars     = (int)ChartGetInteger(0,CHART_VISIBLE_BARS,0);
   if(maxPrice<=minPrice || bars<=0 || g_pixels_x<=0 || g_pixels_y<=0 || BarPoint1==BarPoint2)
      return(0.0);

   double slope = ((PricePoint2-PricePoint1)*g_pixels_y/(maxPrice-minPrice)) / ((BarPoint1-BarPoint2)*g_pixels_x/(double)bars);
   return(MathArctan(slope) * 57.295779513);
}

bool DeleteIfExists(const string name)
{
   if(ObjectFind(0,name)>=0)
      return(ObjectDelete(0,name));
   return(true);
}

bool CreateTrend(const string name,const datetime t1,const double p1,const datetime t2,const double p2,const color clr,const ENUM_LINE_STYLE style,const int width,const bool ray)
{
   DeleteIfExists(name);
   if(!ObjectCreate(0,name,OBJ_TREND,0,t1,p1,t2,p2))
      return(false);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_STYLE,style);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,ray);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   return(true);
}

bool CreateTriangle(const string name,const datetime t1,const double p1,const datetime t2,const double p2,const datetime t3,const double p3,const color clr,const string label)
{
   DeleteIfExists(name);
   if(!ObjectCreate(0,name,OBJ_TRIANGLE,0,t1,p1,t2,p2,t3,p3))
      return(false);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,label);
   return(true);
}

bool CreateTextLabel(const string name,const datetime t1,const double p1,const string text,const color clr,const double angle)
{
   DeleteIfExists(name);
   if(!ObjectCreate(0,name,OBJ_TEXT,0,t1,p1))
      return(false);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetString(0,name,OBJPROP_FONT,"Times New Roman");
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,10);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetDouble(0,name,OBJPROP_ANGLE,angle);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   return(true);
}

bool CreateFibo(const string name,const datetime t1,const double p1,const datetime t2,const double p2,const string NamePattern)
{
   DeleteIfExists(name);
   if(!ObjectCreate(0,name,OBJ_FIBO,0,t1,p1,t2,p2))
      return(false);

   double levels[13]={0.0,0.146,0.236,0.382,0.5,0.618,0.764,0.854,1.0,1.236,1.618,2.618,3.618};
   ObjectSetInteger(0,name,OBJPROP_LEVELS,13);
   ObjectSetInteger(0,name,OBJPROP_LEVELCOLOR,clrYellow);
   ObjectSetInteger(0,name,OBJPROP_LEVELSTYLE,STYLE_DOT);
   ObjectSetInteger(0,name,OBJPROP_LEVELWIDTH,1);

   for(int i=0; i<13; ++i)
   {
      ObjectSetDouble(0,name,OBJPROP_LEVELVALUE,i,levels[i]);
      ObjectSetString(0,name,OBJPROP_LEVELTEXT,i,NamePattern+" - "+DoubleToString(levels[i]*100.0,1)+" %");
   }

   ObjectSetString(0,name,OBJPROP_LEVELTEXT,0, NamePattern+" - 0 % ("+DoubleToString(p2,_Digits)+")");
   ObjectSetString(0,name,OBJPROP_LEVELTEXT,1, NamePattern+" - 14.6 % ("+DoubleToString(p2-(p2-p1)*0.146,_Digits)+")");
   ObjectSetString(0,name,OBJPROP_LEVELTEXT,2, NamePattern+" - 23.6 % ("+DoubleToString(p2-(p2-p1)*0.236,_Digits)+")");
   ObjectSetString(0,name,OBJPROP_LEVELTEXT,3, NamePattern+" - 38.2 % ("+DoubleToString(p2-(p2-p1)*0.382,_Digits)+")");
   ObjectSetString(0,name,OBJPROP_LEVELTEXT,4, NamePattern+" - 50 % ("+DoubleToString(p2-(p2-p1)*0.5,_Digits)+")");
   ObjectSetString(0,name,OBJPROP_LEVELTEXT,5, NamePattern+" - 61.8 % ("+DoubleToString(p2-(p2-p1)*0.618,_Digits)+")");
   ObjectSetString(0,name,OBJPROP_LEVELTEXT,6, NamePattern+" - 76.4 % ("+DoubleToString(p2-(p2-p1)*0.764,_Digits)+")");
   ObjectSetString(0,name,OBJPROP_LEVELTEXT,7, NamePattern+" - 85.4 % ("+DoubleToString(p2-(p2-p1)*0.854,_Digits)+")");
   ObjectSetString(0,name,OBJPROP_LEVELTEXT,8, NamePattern+" - 100 % ("+DoubleToString(p1,_Digits)+")");
   ObjectSetString(0,name,OBJPROP_LEVELTEXT,9, NamePattern+" - 123.6 % ("+DoubleToString(p2-(p2-p1)*1.236,_Digits)+")");
   ObjectSetString(0,name,OBJPROP_LEVELTEXT,10,NamePattern+" - 161.8 % ("+DoubleToString(p2-(p2-p1)*1.618,_Digits)+")");
   ObjectSetString(0,name,OBJPROP_LEVELTEXT,11,NamePattern+" - 261.8 % ("+DoubleToString(p2-(p2-p1)*2.618,_Digits)+")");
   ObjectSetString(0,name,OBJPROP_LEVELTEXT,12,NamePattern+" - 361.8 % ("+DoubleToString(p2-(p2-p1)*3.618,_Digits)+")");
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   return(true);
}

string PatternLabel(const string NamePattern,const string BullBear,const int Depth)
{
   return(NamePattern+"_"+BullBear+"_"+TimeFrame()+"_"+IntegerToString(Depth));
}

bool IsTriangleObject(const string name)
{
   if(ObjectFind(0,name)<0)
      return(false);
   return((ENUM_OBJECT)ObjectGetInteger(0,name,OBJPROP_TYPE)==OBJ_TRIANGLE);
}

string TriangleLabel(const string name)
{
   if(ObjectFind(0,name)<0)
      return("");
   return(ObjectGetString(0,name,OBJPROP_TOOLTIP));
}
