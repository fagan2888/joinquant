//+-----------------------------------------------------------------------------+
//|                                                    chanlun_basenew_0624.mq4 |
//|                                    做蓝线笔；蓝线反转确认开仓，蓝线反转平仓 |
//|                                                        https://www.mql5.com |
//+-----------------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

extern double Lots=1;//下单量
extern int Slip=50;//滑点
extern double StopLoss=0;//止损点
extern int TakeProfit=1;//止盈倍数
extern int    recentKline=5000;//计算最近K线数目
extern int interval_klines=3;//开平仓间隔K线数目时间
input  int    Method=0;//背离判断条件
input int ModeOpen=20;//开仓过滤条件（0-19）
input int ModeClose=0;//平仓过滤条件（0-2）
input double RATIO_RED_PARA=1;//二级别进中枢出中枢效率参数
extern int Buy_Magic=1;
extern int Sell_Magic=2;
input int MaxStopLoss=10000;     // 最大止损点
//+------------------------------------------------------------------+
//| 全局变量                                                         |
int CENTRAL_BLUE_NUM=0;//二级别中枢个数
int CENTRAL_RED_NUM=0;//一级别中枢个数
double DISTENCE_IN_RED=0;//二级别进入中枢距离
double DISTENCE_OUT_RED=100000;//二级别出中枢距离
double RATIO_RED=1;//二级别进中枢出中枢效率
int TREND_RED=0;
int TREND_WHITE=0;
int TREND_BLUE=0;
double RECENT_CENTRAL_EDGE_UP=200000;
double RECENT_CENTRAL_EDGE_DOWN=0;
double UNCERTAIN_RED=0;
double UNCERTAIN_BLUE=0;
bool GAP_BLUE=true;
int BREAK_TIMES_RED=0;
int    ExtLevel=3; // recounting's depth of extremums
string NAME="缠论/cz_笔_0725";
//+------------------------------------------------------------------+
//| Expert initialization function
//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //printf("up:%s,down:%s",DoubleToStr(RECENT_CENTRAL_EDGE_UP),DoubleToStr(RECENT_CENTRAL_EDGE_DOWN));
   int BuyMagic=StrToInteger(IntegerToString(Period()) + IntegerToString(Buy_Magic));
   int SellMagic=StrToInteger(IntegerToString(Period()) + IntegerToString(Sell_Magic));
   int ask_bid=0;
   int i=0,p=0,k_third_idx_s=0;
   double ii=0;
   int rates_total=MathMin(Bars(Symbol(),0),recentKline);
   double zz[];
   ArrayInitialize(zz,0.0);
   ArrayResize(zz,rates_total);
   GetZigZagNumber(rates_total,zz);
   int k=0;//zigzag高低点个数
   double Leg[];
   int Leg_idx[];
   CreateLegs(rates_total,k,Leg,Leg_idx,zz);//根据zigzag值创建原始笔、原始笔位置、原始笔数目k
   int segment_num=0;
   double segment_value[];
   int segment_value_index[];
   double second_high1=0,second_low1=0;
   double buyop=0,buylots=0;
   double sellop=0,selllots=0;
   bool gap_white=true;
   int break_times_blue=0;
   int k_second=0;
   int segment_second_num=0;
   double segment_second_value[];
   int segment_second_value_index[];
   double second_high2=0,second_low2=0;
      //else if(TREND_BLUE==TREND_RED && CENTRAL_BLUE_NUM<2)
      
   if(TREND_BLUE==-1)
     {
      if(OpenBuyLimit(ModeOpen)==true)
        {
         StopLoss=UNCERTAIN_BLUE;
         CreateSegments(GAP_BLUE,BREAK_TIMES_RED,TREND_BLUE,segment_num,Leg,Leg_idx,segment_value,segment_value_index,k,second_high1,second_low1);//创建一级线段

         if(TREND_BLUE==1)
           {
            double takeProfit=Ask+TakeProfit*(segment_value[segment_num]-StopLoss);
            if(selldanshu(Symbol(),SellMagic,buyop,buylots)>0)
               closesell(Symbol(),SellMagic,Slip);
            if(Ask-StopLoss<=Point*MaxStopLoss && selldanshu(Symbol(),SellMagic,buyop,buylots)==0)
              {
               buy(Lots,Slip,StopLoss,takeProfit,"long"+IntegerToString(Period()),BuyMagic);//止盈
               SendNotification(Symbol()+": 做多 原因：三类买点");
              }
           }
        }
     }
   else
      if(TREND_BLUE==1)
        {
         if(OpenSellLimit(ModeOpen)==TRUE)
           {
            StopLoss=UNCERTAIN_BLUE;
            CreateSegments(GAP_BLUE,BREAK_TIMES_RED,TREND_BLUE,segment_num,Leg,Leg_idx,segment_value,segment_value_index,k,second_high1,second_low1);//创建一级线段

            if(TREND_BLUE==-1)
              {
               double takeProfit=Bid-TakeProfit*(StopLoss-segment_value[segment_num]);
               if(buydanshu(Symbol(),BuyMagic,sellop,selllots)>0)
                  closebuy(Symbol(),BuyMagic,Slip);
               if(StopLoss-Bid<=Point*MaxStopLoss && buydanshu(Symbol(),BuyMagic,sellop,selllots)==0)
                 {
                  sell(Lots,Slip,StopLoss,takeProfit,"short"+IntegerToString(Period()),SellMagic);
                  SendNotification(Symbol()+": 做空 原因：三类卖点");
                 }
              }
           }
        }

   if(segment_num==0)
     {
      CreateSegments(GAP_BLUE,BREAK_TIMES_RED,TREND_BLUE,segment_num,Leg,Leg_idx,segment_value,segment_value_index,k,second_high1,second_low1);//创建一级线段
     }

   k_second=segment_num+1;
   CreateSegments(gap_white,break_times_blue,TREND_WHITE,segment_second_num,segment_value,segment_value_index,segment_second_value,
                  segment_second_value_index,k_second,second_high2,second_low2);//创建二级线段

   double in=0,out=0;
   UNCERTAIN_BLUE=segment_value[segment_num];
   UNCERTAIN_RED=Leg[k-1];
   double up=0,down=0;
   if(k>4)
     {
      RATIO_RED=GetRatio(Leg_idx[k-1],Leg_idx[k-2],Leg_idx[k-3],Leg_idx[k-4],Leg[k-1],Leg[k-2],Leg[k-3],Leg[k-4]);
      if(Leg[k-1]>Leg[k-2])
         TREND_RED=1;
      else
         TREND_RED=-1;
     }
   if(segment_num>0)
     {
      CENTRAL_RED_NUM=DrawnCentral(TREND_BLUE,1,rates_total,segment_value_index[segment_num-1],Leg,
                                   Leg_idx,k,Period(),up,down,DISTENCE_IN_RED,DISTENCE_OUT_RED);//一级中枢

     }
   if(segment_second_num>0)
     {
      DrawnCentral(TREND_WHITE,2,rates_total,segment_second_value_index[segment_second_num-1],segment_value,
                   segment_value_index,k_second,Period(),RECENT_CENTRAL_EDGE_UP,RECENT_CENTRAL_EDGE_DOWN,in,out);//二级中枢
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CloseLimit(int mode_close)
  {
   if(mode_close==0)
     {
      if(CENTRAL_RED_NUM>=2 && DiverMethod(Method,DISTENCE_IN_RED,DISTENCE_OUT_RED,RATIO_RED,RATIO_RED_PARA)==TRUE)
         return true;
     }
   if(mode_close==2)
     {
      if(CENTRAL_RED_NUM>=2)
         return true;
     }
   if(mode_close==1)
     {
      if(DiverMethod(Method,DISTENCE_IN_RED,DISTENCE_OUT_RED,RATIO_RED,RATIO_RED_PARA)==TRUE)
         return true;
     }
   if(mode_close==3)
      return true;
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OpenBuyLimit(int mode)
  {
   bool case1=(TREND_WHITE==1);
   bool case2=(GAP_BLUE==FALSE || BREAK_TIMES_RED==1);
   bool case3=(CENTRAL_RED_NUM>=2);
   bool case4=(DiverMethod(Method,DISTENCE_IN_RED,DISTENCE_OUT_RED,RATIO_RED,RATIO_RED_PARA)==TRUE);
   if(TREND_BLUE==-1)
     {
      if(mode==0)
        {
         if(case1 && (case2 && (case3 && case4)))
            return true;
        }
      if(mode==1)
        {
         if(case2 || (case3 && case4))
            return true;
        }
      if(mode==2)
        {
         if(case2 && case3 && case4)
            return true;
        }
      if(mode==3)
        {
         if(case3 && case4)
            return true;
        }
      if(mode==4)
        {
         if(case2 && case3)
            return true;
        }
      if(mode==5)
        {
         if(case2 && case4)
            return true;
        }
      if(mode==6)
        {
         if(case2 && (case3 || case4))
            return true;
        }
      if(mode==7)
        {
         if(case3)
            return true;
        }
      if(mode==8)
        {
         if(case4)
            return true;
        }
      if(mode==9)
        {
         if(case2)
            return true;
        }
      if(mode==10)
        {
         if(case1)
            return true;
        }
      if(mode==11)
        {
         if((case2 || (case3 && case4)) && case1)
            return true;
        }
      if(mode==12)
        {
         if(case2 && case3 && case4 && case1)
            return true;
        }
      if(mode==13)
        {
         if(case3 && case4 && case1)
            return true;
        }
      if(mode==14)
        {
         if(case2 && case3 && case1)
            return true;
        }
      if(mode==15)
        {
         if(case2 && case4 && case1)
            return true;
        }
      if(mode==16)
        {
         if(case2 && (case3 || case4) && case1)
            return true;
        }
      if(mode==17)
        {
         if(case3 && case1)
            return true;
        }
      if(mode==18)
        {
         if(case4 && case1)
            return true;
        }
      if(mode==19)
        {
         if(case2 && case1)
            return true;
        }
      if(mode==20)
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OpenSellLimit(int mode)
  {
   bool case1=(TREND_WHITE==-1);
   bool case2=(GAP_BLUE==FALSE || BREAK_TIMES_RED==1);
   bool case3=(CENTRAL_RED_NUM>=2);
   bool case4=(DiverMethod(Method,DISTENCE_IN_RED,DISTENCE_OUT_RED,RATIO_RED,RATIO_RED_PARA)==TRUE);
   if(TREND_BLUE==1)
     {
      if(mode==0)
        {
         if(case1 && (case2 && (case3 && case4)))
            return true;
        }
      if(mode==1)
        {
         if(case2 || (case3 && case4))
            return true;
        }
      if(mode==2)
        {
         if(case2 && case3 && case4)
            return true;
        }
      if(mode==3)
        {
         if(case3 && case4)
            return true;
        }
      if(mode==4)
        {
         if(case2 && case3)
            return true;
        }
      if(mode==5)
        {
         if(case2 && case4)
            return true;
        }
      if(mode==6)
        {
         if(case2 && (case3 || case4))
            return true;
        }
      if(mode==7)
        {
         if(case3)
            return true;
        }
      if(mode==8)
        {
         if(case4)
            return true;
        }
      if(mode==9)
        {
         if(case2)
            return true;
        }
      if(mode==10)
        {
         if(case1)
            return true;
        }
      if(mode==11)
        {
         if((case2 || (case3 && case4)) && case1)
            return true;
        }
      if(mode==12)
        {
         if(case2 && case3 && case4 && case1)
            return true;
        }
      if(mode==13)
        {
         if(case3 && case4 && case1)
            return true;
        }
      if(mode==14)
        {
         if(case2 && case3 && case1)
            return true;
        }
      if(mode==15)
        {
         if(case2 && case4 && case1)
            return true;
        }
      if(mode==16)
        {
         if(case2 && (case3 || case4) && case1)
            return true;
        }
      if(mode==17)
        {
         if(case3 && case1)
            return true;
        }
      if(mode==18)
        {
         if(case4 && case1)
            return true;
        }
      if(mode==19)
        {
         if(case2 && case1)
            return true;
        }
      if(mode==20)
         return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetRatio(int segment_value_index_num0,int segment_value_index_num1,int segment_value_index_num2,int segment_value_index_num3,
                double segment_value_num0,double segment_value_num1,double segment_value_num2,double segment_value_num3)
  {
   double angle1=MathAbs((segment_value_num1-segment_value_num0)/(segment_value_index_num1-segment_value_index_num0));
   double angle2=MathAbs((segment_value_num3-segment_value_num2)/(segment_value_index_num3-segment_value_index_num2));
   return angle1/angle2;
  }
//+------------------------------------------------------------------+
//|   画出最新线段的中枢                                      |
//+------------------------------------------------------------------+
int DrawnCentral(int trend,int rank,int rates_total,int segment_value_index_num1,double &leg[],
                 int &leg_idx[],int k,int period,double &central_up,double &central_down,double &distance_in,double &distance_out)
  {
   central_up=10000000;
   central_down=0;
   int kk=0,i=0,j=0;
   distance_in=0;
   distance_out=0;
   for(kk=k-1;kk>=0;kk--)
     {
      if(leg_idx[kk]==segment_value_index_num1)
        {
         break;
        }
     }
   int b=kk;
   int central_num=0,central_num_all=0;
   int last_idx_s=0,last_idx_e=0;
   double last_up=0,last_down=100000000,new_down=0,new_up=0;
   if(k-kk<=4)return 0;
   for(j=kk;j<=k-2;j++)
     {
      if(b>k-5)break;
      for(i=b;i<=k-5;i++)
        {
         if(leg[i]>leg[i+1] && trend==1)
           {
            new_up=MathMin(leg[i],leg[i+2]);
            new_down=MathMax(leg[i+1],leg[i+3]);
            if(new_up<=new_down)continue;
            if(new_up>new_down)
              {
               if(new_down>last_up || new_up<last_down)
                 {
                  if(central_num==0||i>last_idx_e)
                    {
                     last_up=new_up;
                     last_down=new_down;
                     central_num++;
                     central_up=last_up;
                     central_down=last_down;
                     last_idx_s=i;
                     last_idx_e=i+3;
                     if(last_idx_s>0)distance_in=(new_down+new_up)/2-leg[last_idx_s-1];
                     distance_out=leg[i+4]-(new_down+new_up)/2;
                     b=i+2;
                     break;
                    }
                 }
               else if(central_num>0)
                 {
                  new_up=MathMin(last_up,new_up);
                  new_down=MathMax(last_down,new_down);
                  if(new_up>new_down)
                    {
                     last_up=new_up;
                     last_down=new_down;
                     central_up=last_up;
                     central_down=last_down;
                     last_idx_e=i+3;
                     if(last_idx_s>0)distance_in=(new_down+new_up)/2-leg[last_idx_s-1];
                     distance_out=leg[i+4]-(new_down+new_up)/2;
                     b=i+2;
                     break;
                    }
                 }
              }
           }
         else if(leg[i]<leg[i+1] && trend==-1)
           {
            new_up=MathMin(leg[i+1],leg[i+3]);
            new_down=MathMax(leg[i],leg[i+2]);
            if(new_up<=new_down)continue;
            if(new_up>new_down)
              {
               if(new_down>last_up || new_up<last_down)
                 {
                  if(central_num==0||i>last_idx_e)
                    {
                     last_up=new_up;
                     last_down=new_down;
                     central_num++;
                     central_up=last_up;
                     central_down=last_down;
                     last_idx_s=i;
                     last_idx_e=i+3;
                     if(last_idx_s>0)distance_in=leg[last_idx_s-1]-(new_down+new_up)/2;
                     distance_out=(new_down+new_up)/2-leg[i+4];
                     b=i+2;
                     break;
                    }
                 }
               else if(central_num>0)
                 {
                  new_up=MathMin(last_up,new_up);
                  new_down=MathMax(last_down,new_down);
                  if(new_up>new_down)
                    {
                     last_up=new_up;
                     last_down=new_down;
                     central_up=last_up;
                     central_down=last_down;
                     last_idx_e=i+3;
                     if(last_idx_s>0)distance_in=leg[last_idx_s-1]-(new_down+new_up)/2;
                     distance_out=(new_down+new_up)/2-leg[i+4];
                     b=i+2;
                     break;
                    }
                 }
              }
           }
        }
     }
   return(central_num);
  }
//+-----------------------------------------------------------------------+
//|获取各个级别最终趋势                                                   |
//+-----------------------------------------------------------------------+
int buy(double lots,int slip,double sl,double tp,string com,int buymagic)
  {
   int a=0;
   int a1=0;
   int a2=0;
   bool zhaodan=false;

   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         string zhushi=OrderComment();
         int ma=OrderMagicNumber();
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUY && zhushi==com && ma==buymagic)
           {
            zhaodan=true;
            break;
           }
        }
     }
   for(int i=0; i<OrdersHistoryTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true)
        {
         int ma=OrderMagicNumber();
         datetime t=OrderCloseTime();
         if(OrderSymbol()==Symbol() && Time[0]-t<Period()*interval_klines*60 && ma==buymagic)
           {
            zhaodan=true;
            break;
           }
        }
     }
   if(zhaodan==false)
     {
      a1=OrderSend(Symbol(),OP_BUY,lots,Ask,slip,
                   NormalizeDouble(MathMin(sl,Bid-Point*MarketInfo(Symbol(),MODE_STOPLEVEL)),Digits),
                   NormalizeDouble(MathMax(tp,Ask+Point*MarketInfo(Symbol(),MODE_STOPLEVEL)),Digits),com,buymagic,0,Red);
      a2=OrderSend(Symbol(),OP_BUY,lots,Ask,slip,
                   NormalizeDouble(MathMin(sl,Bid-Point*MarketInfo(Symbol(),MODE_STOPLEVEL)),Digits),
                   0,com,buymagic,0,Red);
      printf(IntegerToString(a1));
      a=a1+a2;
     }
   return(a);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int sell(double lots,int slip,double sl,double tp,string com,int sellmagic)
  {
   int a=0;
   bool zhaodan=false;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         string zhushi=OrderComment();
         int ma=OrderMagicNumber();
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELL && zhushi==com && ma==sellmagic)
           {
            zhaodan=true;
            break;
           }
        }
     }
   for(int i=0; i<OrdersHistoryTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true)
        {
         int ma=OrderMagicNumber();
         datetime t=OrderCloseTime();

         if(OrderSymbol()==Symbol() && Time[0]-t<Period()*interval_klines*60 && ma==sellmagic)
           {
            zhaodan=true;
            break;
           }
        }
     }
   if(zhaodan==false)
     {
      a=OrderSend(Symbol(),OP_SELL,lots,Bid,slip,
                  NormalizeDouble(MathMax(sl,Ask+Point*MarketInfo(Symbol(),MODE_STOPLEVEL)),Digits),
                  NormalizeDouble(MathMin(tp,Bid-Point*MarketInfo(Symbol(),MODE_STOPLEVEL)),Digits),com,sellmagic,0,Green);
      a=OrderSend(Symbol(),OP_SELL,lots,Bid,slip,
                  NormalizeDouble(MathMax(sl,Ask+Point*MarketInfo(Symbol(),MODE_STOPLEVEL)),Digits),
                  0,com,sellmagic,0,Green);
     }
   return(a);
  }


//+------------------------------------------------------------------+
//|计算开仓点                                                        |
//+------------------------------------------------------------------+
int DrawnLastBreakDot(int rates_total,double segment_value_num1,double segment_value_num0,int segment_value_index_num1,double &leg[],
                      int &leg_idx[],int k,int period,double second_high,double second_low)
  {
   int kk=0,a=0,i=0,f=0;
   for(kk=k-1; kk>=0; kk--)
     {
      if(leg_idx[kk]==segment_value_index_num1)
        {
         break;
        }
     }
   if(segment_value_num1>segment_value_num0)
     {
      for(i=kk; i<k-3; i=i+2)
        {
         if(leg[kk+1]<=second_high)
           {
            if(leg[i+3]<leg[i+1])
              {
               for(f=leg_idx[i+2]-1; f>=leg_idx[i+3]; f--)
                 {
                  if(Low[f]<leg[i+1])
                    {
                     return -1;
                    }
                 }
               break;
              }
           }

         else
            if(leg[i+3]<leg[i+1])
              {
               a++;
               if(a==2)
                 {
                  for(f=leg_idx[i+2]-1; f>=leg_idx[i+3]; f--)
                    {
                     if(Low[f]<leg[i+1])
                       {
                        return -1;
                       }
                    }
                  break;
                 }
              }
        }
     }
   if(segment_value_num1<segment_value_num0)
     {
      for(i=kk; i<k-3; i=i+2)
        {
         if(leg[kk+1]>=second_low)
           {
            if(leg[i+3]>leg[i+1])
              {
               for(f=leg_idx[i+2]-1; f>=leg_idx[i+3]; f--)
                 {
                  if(High[f]>leg[i+1])
                    {
                     return 1;
                    }
                 }
               break;
              }
           }
         else
            if(leg[i+3]>leg[i+1])
              {
               a++;
               if(a==2)
                 {
                  for(f=leg_idx[i+2]-1; f>=leg_idx[i+3]; f--)
                    {
                     if(High[f]>leg[i+1])
                       {
                        return 1;
                       }
                    }
                  break;
                 }
              }
        }
     }
   return 0;
  }

//+------------------------------------------------------------------------------------------+
//| 判断进出中枢距离和角度是否背驰，method（0：距离背驰，1：角度背驰，2：距离角度同时背驰）  |                                        |
//+------------------------------------------------------------------------------------------+
bool DiverMethod(int method,double distance_in,double distance_out,double ratio,double ratio_para)
  {
   if(method==0)//距离和角度背驰
     {
      if(DiverDistance(distance_in,distance_out)==true &&
         DiverAngleRatio(ratio,ratio_para)==true)
         return true;
     }
   if(method==1)//角度背驰
     {
      if(DiverAngleRatio(ratio,ratio_para)==true)
         return true;
     }
   if(method==2)//距离背驰
     {
      if(DiverDistance(distance_in,distance_out)==true)
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| 判断进出中枢距离是否背驰，rank{3：白线笔，2：蓝线笔，1：紫线笔}  |                                      |
//+------------------------------------------------------------------+
bool DiverDistance(double distance_in,double distance_out)
  {
   if(distance_out<distance_in)
      return true;
   else
      return false;
  }
//+------------------------------------------------------------------+
//| 判断进出中枢角度是否背驰，rank{3：白线笔，2：蓝线笔，1：紫线笔}  |                                      |
//+------------------------------------------------------------------+
bool DiverAngleRatio(double ratio,double ratio_para)
  {
   if(ratio<ratio_para)
      return true;
   else
      return false;
  }
//+------------------------------------------------------------------+
//| 重新定义不确定高点和低点                                         |
//+------------------------------------------------------------------+
void RenewUncertain(double &uncertain,int &uncertain_idx,
                    double &second,double leg,int leg_idx,int array,int &b)
  {
   second=uncertain;
   uncertain=leg;
   uncertain_idx=leg_idx;
   b=array;
  }
//+------------------------------------------------------------------+
//| 分界点重新定义                                                   |
//+------------------------------------------------------------------+
void RenewDividedDot(int trend,double &segment_value[],int &segment_value_index[],
                     double &uncertain_high,int &uncertain_high_idx,
                     double &uncertain_low,int &uncertain_low_idx,
                     double &second_high,double &second_low,
                     int segment_num,double &leg[],int &leg_idx[],int k,int &b,int &e)
  {
   int d=0,a=0,x=0;
   if(trend==1)
     {
      for(d=b+1; d<k-3; d=d+2) //循环寻找是否需要重新确认低点
        {
         if(leg[d+2]<leg[d])
            break;
         if(leg[d+3]>leg[d+1])
           {
            if(leg[b+2]>=leg[b-1])
              {
               x=1;
               break;
              }
            else
              {
               a++;
               if(a==2)
                 {
                  x=1;
                  break;
                 }
              }
           }
        }
      if(x==1)
        {
         segment_value[segment_num-1]=leg[b+1];
         segment_value_index[segment_num-1]=leg_idx[b+1];
         uncertain_low=leg[b+1];
         uncertain_low_idx=leg_idx[b+1];
         uncertain_high=leg[d+3];
         uncertain_high_idx=leg_idx[d+3];
         second_high=leg[d+1];
         b=d+3;
         e++;
        }
     }
   else
      if(trend==-1)
        {
         for(d=b+1; d<k-3; d=d+2) //循环寻找是否需要重新确认低点
           {
            if(leg[d+2]>leg[d])
               break;
            if(leg[d+3]<leg[d+1])
              {
               if(leg[b+2]<=leg[b-1])
                 {
                  x=1;
                  break;
                 }
               else
                 {
                  a++;
                  if(a==2)
                    {
                     x=1;
                     break;
                    }
                 }
              }
           }
         if(x==1)
           {
            segment_value[segment_num-1]=leg[b+1];
            segment_value_index[segment_num-1]=leg_idx[b+1];
            uncertain_high=leg[b+1];
            uncertain_high_idx=leg_idx[b+1];
            uncertain_low=leg[d+3];
            uncertain_low_idx=leg_idx[d+3];
            second_low=leg[d+1];
            b=d+3;
            e++;
           }
        }
  }
//+------------------------------------------------------------------+
//| 获取初始处理笔时候三个点的函数，GetFirstThreeDot               |
//+------------------------------------------------------------------+
void GetFirstThreeDot(int trend,double &segment_value[],int &segment_value_index[],
                      double &uncertain_high,int &uncertain_high_idx,
                      double &uncertain_low,int &uncertain_low_idx,
                      double &second_high,double &second_low,
                      int &segment_num,double leg_m,int leg_idx_m,double leg_m1,
                      double leg_m3,int leg_idx_m3,int k)
  {

   ArrayInitialize(segment_value,0.0);
   ArrayInitialize(segment_value_index,0);
   ArrayResize(segment_value,MathMax(10,k));
   ArrayResize(segment_value_index,MathMax(10,k));
   if(1==trend)
     {
      segment_value[0]=leg_m;
      segment_value_index[0]=leg_idx_m;
      second_high=leg_m1;
      uncertain_high=leg_m3;
      uncertain_high_idx=leg_idx_m3;
      uncertain_low=leg_m;
      uncertain_low_idx=leg_idx_m;
      segment_num++;
     }
   if(-1==trend)
     {
      segment_value[0]=leg_m;
      segment_value_index[0]=leg_idx_m;
      second_low=leg_m1;
      uncertain_low=leg_m3;
      uncertain_low_idx=leg_idx_m3;
      uncertain_high=leg_m;
      uncertain_high_idx=leg_idx_m;
      segment_num++;
     }
  }
//+------------------------------------------------------------------+
//| 获取初始趋势及初始线段方向的函数,返回0代表失败                   |
//+------------------------------------------------------------------+
int GetInialTrend(int &m,int k,double &leg[])
  {
   m=0;
   int trend=0;
   for(m=0; m<k-3; m++) //找出第一个线段趋势
     {
      if(leg[m]<leg[m+2] && leg[m+1]<leg[m+3] && leg[m]<leg[m+1])
        {
         //确定初始趋势为向上，
         trend=1;
         break;
        }
      if(leg[m]>leg[m+2] && leg[m+1]>leg[m+3] && leg[m]>leg[m+1])
        {
         //确定初始趋势为向下
         trend=-1;
         break;
        }
     }
   return trend;
  }
//+------------------------------------------------------------------+
//| 判断是否发生反转，JudgeTurn                                      |
//+------------------------------------------------------------------+
int JudgeTurn(int trend,double segment_value_num1,
              double &uncertain,int &uncertain_idx,double &second,
              double &leg[],int &leg_idx[],int &b,int k,int &i,int &break_num,bool &gap)
  {
   int x=0;
   break_num=0;
   gap=true;
   if(trend==1)
     {
      if(b+1<k)
        {
         if(leg[b+1]<=second)
            gap=false;
        }
      for(i=b; i<k-2; i=i+2)
        {
         if(leg[i+2]>uncertain)//向上趋势再创新高
           {
            RenewUncertain(uncertain,uncertain_idx,
                           second,leg[i+2],leg_idx[i+2],i+2,b);
            break;
           }
         else//没有创新高，判断是否反转
           {
            if(i+3>=k)
               break;
            if(leg[i+3]<segment_value_num1 && leg[i+3]<leg[i+1])
              {
               x=1;
               break;
              }
            else
               if(leg[b+1]<=second) //无缺口，一次确认
                 {
                  if(leg[i+3]<leg[i+1])
                    {
                     x=1;
                     break;
                    }
                 }
               else
                  if(leg[i+3]<leg[i+1])//有缺口，需确认两次
                    {
                     break_num++;
                     if(break_num==2)
                       {
                        x=1;
                        break;
                       }
                    }
           }
        }
     }
   if(trend==-1)
     {
      if(b+1<k)
        {
         if(leg[b+1]>=second)
            gap=false;
        }
      for(i=b; i<k-2; i=i+2)
        {
         if(leg[i+2]<uncertain)//向上趋势再创新高
           {
            RenewUncertain(uncertain,uncertain_idx,second,leg[i+2],leg_idx[i+2],i+2,b);
            break;
           }
         else//没有创新高，判断是否反转
           {
            if(i+3>=k)
               break;
            if(leg[i+3]>segment_value_num1 && leg[i+3]>leg[i+1])
              {
               x=1;
               break;
              }
            else
               if(leg[b+1]>=second) //无缺口，一次确认
                 {
                  if(leg[i+3]>leg[i+1])
                    {
                     x=1;
                     break;
                    }
                 }
               else
                  if(leg[i+3]>leg[i+1])//有缺口，需确认两次
                    {
                     break_num++;
                     if(break_num==2)
                       {
                        x=1;
                        break;
                       }
                    }
           }
        }
     }
   return x;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrendTurn(int &trend,double &segment_value[],int &segment_value_index[],
               double &uncertain1,int &uncertain_idx1,double &uncertain2,int &uncertain_idx2,double &second,
               int &segment_num,double leg1,double leg3,int leg_idx3,int i,int &b,int &e)
  {
   trend=-trend;
   segment_value[segment_num]=uncertain1;
   segment_value_index[segment_num]=uncertain_idx1;
   segment_num++;
   uncertain2=leg3;
   uncertain_idx2=leg_idx3;
   second=leg1;
   b=i+3;
   e=0;
  }
//+------------------------------------------------------------------+
//| 获取初始趋势之后的所有的线段点                                   |
//+------------------------------------------------------------------+
void GetOtherDot(int &trend,double &segment_value[],int &segment_value_index[],
                 double &uncertain_high,int &uncertain_high_idx,
                 double &uncertain_low,int &uncertain_low_idx,
                 double &second_high,double &second_low,
                 int &segment_num,double &leg[],int &leg_idx[],int m,int k,int &break_num,bool &gap)
  {
//下面开始遍历整个Leg数组，来进行线段的处理逻辑，根据场景进行划分；
   int c=0,d=0,e=0;
   int b=m+3;
   int x=0;
   int i=0;
   break_num=0;
   for(c=0; c<k-2; c++)
     {
      if(b+3>k)
         break;
      if(trend==1)
        {
         //判断是否要做分界点重新处理
         if(segment_num>1 && b+4<k && e<2 && leg[b+1]<uncertain_low)
           {
            if(uncertain_high<=segment_value[segment_num-2])
              {
               RenewDividedDot(trend,segment_value,segment_value_index,uncertain_high,uncertain_high_idx,
                               uncertain_low,uncertain_low_idx,second_high,second_low,segment_num,leg,leg_idx,k,b,e);
              }
           }

         x=JudgeTurn(trend,segment_value[segment_num-1],
                     uncertain_high,uncertain_high_idx,second_high,
                     leg,leg_idx,b,k,i,break_num,gap);
         if(x==1)
            TrendTurn(trend,segment_value,segment_value_index,uncertain_high,
                      uncertain_high_idx,uncertain_low,uncertain_low_idx,second_low,
                      segment_num,leg[i+1],leg[i+3],leg_idx[i+3],i,b,e);
        }
      else
         if(trend==-1)
           {
            //判断是否要做分界点重新处理
            if(segment_num>1 && b+4<k && e<2 && leg[b+1]>uncertain_high)
              {
               if(uncertain_low>=segment_value[segment_num-2])
                 {
                  RenewDividedDot(trend,segment_value,segment_value_index,uncertain_high,uncertain_high_idx,
                                  uncertain_low,uncertain_low_idx,second_high,second_low,segment_num,leg,leg_idx,k,b,e);
                 }
              }
            x=JudgeTurn(trend,segment_value[segment_num-1],
                        uncertain_low,uncertain_low_idx,second_low,
                        leg,leg_idx,b,k,i,break_num,gap);

            if(x==1)
               TrendTurn(trend,segment_value,segment_value_index,uncertain_low,
                         uncertain_low_idx,uncertain_high,uncertain_high_idx,second_high,
                         segment_num,leg[i+1],leg[i+3],leg_idx[i+3],i,b,e);
           }
     }
  }
//+------------------------------------------------------------------+
//|获取最后一个动态的线段点                                          |
//+------------------------------------------------------------------+
void GetLastDot(int trend,int segment_num,double &segment_value[],
                int &segment_value_index[],double uncertain_high,double uncertain_low,
                int uncertain_high_idx,int uncertain_low_idx)
  {
   if(segment_num>=1)
     {
      if(segment_value[segment_num-1]==Low[segment_value_index[segment_num-1]]&&trend==1)
        {
         segment_value[segment_num]=uncertain_high;
         segment_value_index[segment_num]=uncertain_high_idx;
        }
      if(segment_value[segment_num-1]==High[segment_value_index[segment_num-1]]&&trend==-1)
        {
         segment_value[segment_num]=uncertain_low;
         segment_value_index[segment_num]=uncertain_low_idx;
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CreateSegments(bool &gap,int &break_num,int &trend,int &segment_num,double &leg[],int &leg_idx[],
                   double &segment_value[],int &segment_value_index[],int k,double &second_high,double &second_low)
  {
   ArrayResize(segment_value,MathMax(10,k));
   ArrayResize(segment_value_index,MathMax(10,k));
   ArrayInitialize(segment_value,0.0);
   ArrayInitialize(segment_value_index,0);
   if(k<5)
      return 0;
   int m=0;
   trend=GetInialTrend(m,k,leg);
   if(trend==0 || m+6>k)//笔的个数不足以判断接下来的趋势
     {
      segment_value[0]=leg[m];
      segment_value_index[0]=leg_idx[m];
      segment_num=1;
      if(m+6>k && trend!=0)
        {
         segment_value[1]=leg[m+3];
         segment_value_index[1]=leg_idx[m+3];
         segment_num=2;
        }

      return 0;
     }
   second_high=0;
   second_low=0;
   double uncertain_high=0,uncertain_low=0;//次高点，最新尚未确定的线段高点，次低点，最新尚未确定的线段的低点
   int uncertain_high_idx=0,uncertain_low_idx=0;
   segment_num=0;
   GetFirstThreeDot(trend,segment_value,segment_value_index,uncertain_high,
                    uncertain_high_idx,uncertain_low,uncertain_low_idx,second_high,
                    second_low,segment_num,leg[m],leg_idx[m],leg[m+1],leg[m+3],leg_idx[m+3],k);
   GetOtherDot(trend,segment_value,segment_value_index,uncertain_high,uncertain_high_idx,
               uncertain_low,uncertain_low_idx,second_high,second_low,
               segment_num,leg,leg_idx,m,k,break_num,gap);

   GetLastDot(trend,segment_num,segment_value,segment_value_index,uncertain_high,uncertain_low,
              uncertain_high_idx,uncertain_low_idx);
   return segment_num;
  }
//+------------------------------------------------------------------+
//|       创建笔的函数                                               |
//+------------------------------------------------------------------+
void CreateLegs(int total,int &k,double &leg[],int &leg_idx[],double &buffer[])
  {
   k=0;
   ArrayInitialize(leg,0.0);
   ArrayInitialize(leg_idx,0);
   ArrayResize(leg,10000);
   ArrayResize(leg_idx,10000);
   int i=0;
   for(i=total-1; i>-1; i--) //zigzag的高低点
     {
      if(buffer[i]!=0)
        {
         leg[k]=buffer[i];
         leg_idx[k]=i;
         k++;
        }
     }
   ArrayResize(leg,k);
   ArrayResize(leg_idx,k);
  }
//+------------------------------------------------------------------+
//|       创建笔的函数，即zigzag函数                                 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetZigZagNumber(const int rates_total,double &ExtZigzagBuffer[])
  {
   ArrayInitialize(ExtZigzagBuffer,0.0);
   ArrayResize(ExtZigzagBuffer,rates_total);
   for(int i=0; i<rates_total; i++)
     {
      ExtZigzagBuffer[i]=iCustom(NULL,0,NAME,0,i);
     }
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closebuy(string symbol,int magic,int slip)
  {
   double buyop,buylots;
   bool a;
   bool b=true;
   while(buydanshu(symbol,magic,buyop,buylots)>0 && b==true)
     {
      int t=OrdersTotal();
      for(int i=t-1; i>=0; i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
           {
            if(OrderSymbol()==symbol && OrderType()==OP_BUY && OrderMagicNumber()==magic)
              {
               if(Time[0]-OrderOpenTime()>Period()*60*interval_klines)
                 {
                  a=OrderClose(OrderTicket(),OrderLots(),Bid,slip,White);
                 }
               else
                  b=false;

              }
           }
        }
      Sleep(800);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closesell(string symbol,int magic,int slip)
  {
   double sellop,selllots;
   bool a;
   bool b=true;
   while(selldanshu(symbol,magic,sellop,selllots)>0 && b==true)
     {
      int t=OrdersTotal();
      for(int i=t-1; i>=0; i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
           {
            if(OrderSymbol()==symbol && OrderType()==OP_SELL && OrderMagicNumber()==magic)
              {
               if(Time[0]-OrderOpenTime()>Period()*60*interval_klines)
                 {
                  a=OrderClose(OrderTicket(),OrderLots(),Ask,slip,White);
                 }
               else
                  b=false;
              }
           }
        }
      Sleep(800);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void buyxiugaitp(double tp,int magic)
  {
   bool a;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUY && OrderMagicNumber()==magic)
           {
            if(NormalizeDouble(OrderTakeProfit(),Digits)!=NormalizeDouble(tp,Digits))
              {
               a=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),tp,0,Green);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sellxiugaitp(double tp,int magic)
  {
   bool a;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELL && OrderMagicNumber()==magic)
           {
            if(NormalizeDouble(OrderTakeProfit(),Digits)!=NormalizeDouble(tp,Digits))
              {
               a=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),tp,0,Green);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double avgbuyprice(int magic)
  {
   double a=0;
   int shuliang=0;
   double pricehe=0;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUY && OrderMagicNumber()==magic)
           {
            pricehe=pricehe+OrderOpenPrice();
            shuliang++;
           }
        }
     }
   if(shuliang>0)
     {
      a=pricehe/shuliang;
     }
   return(a);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double avgsellprice(int magic)
  {
   double a=0;
   int shuliang=0;
   double pricehe=0;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELL && OrderMagicNumber()==magic)
           {
            pricehe=pricehe+OrderOpenPrice();
            shuliang++;
           }
        }
     }
   if(shuliang>0)
     {
      a=pricehe/shuliang;
     }
   return(a);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double flots(double dlots)
  {
   double fb=NormalizeDouble(dlots/MarketInfo(Symbol(),MODE_MINLOT),0);
   return(MarketInfo(Symbol(),MODE_MINLOT)*fb);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int buydanshu(string symbol,int magic,double &op,double &lots)
  {
   int a=0;
   op=0;
   lots=0;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderSymbol()==symbol && OrderType()==OP_BUY && OrderMagicNumber()==magic)
           {
            a++;
            op=OrderOpenPrice();
            lots=OrderLots();

           }
        }
     }
   return(a);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int selldanshu(string symbol,int magic,double &op,double &lots)
  {
   int a=0;
   op=0;
   lots=0;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderSymbol()==symbol && OrderType()==OP_SELL && OrderMagicNumber()==magic)
           {
            a++;
            op=OrderOpenPrice();
            lots=OrderLots();
           }
        }
     }
   return(a);
  }
//+------------------------------------------------------------------+
