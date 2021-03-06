//+------------------------------------------------------------------+
//|                                         chanlun_basenew_0624.mq4 |
//|            做白线中枢的三类买卖点；中枢静态，包含蓝线笔的距离背驰、角度背驰 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

extern double Lots=0.1;//下单量
extern int Slip=50;//滑点
extern double StopLoss=0;//止损点
extern double TakeProfit=0;//止盈点
extern int    recentKline=20000;//计算最近K线数目
input  int    Method=0;//背离判断条件
input int ModeOpen=0;//开仓过滤条件（0-19）
input int ModeClose=0;//平仓过滤条件（0-2）
input double RATIO_BLUE_PARA=1;//二级别进中枢出中枢效率参数
extern int Magic=1;
input int MaxStopLoss=10000;     // 最大止损点
//+------------------------------------------------------------------+
//| 全局变量                                                         |         
//+------------------------------------------------------------------+
//int CENTRAL_WHITE=0;//三级笔中枢个数
int CENTRAL_BLUE_NUM=0;//二级别中枢个数
int CENTRAL_RED_NUM=0;//一级别中枢个数
//double DISTENCE_IN_3=0;//三级别进入中枢距离
double DISTENCE_IN_BLUE=0;//二级别进入中枢距离
double DISTENCE_OUT_BLUE=100000;//二级别出中枢距离
double RATIO_BLUE=1;//二级别进中枢出中枢效率
int TREND_GREEN=0;
int TREND_WHITE=0;
int TREND_BLUE=0;
double RECENT_CENTRAL_EDGE_UP=20000;
double RECENT_CENTRAL_EDGE_DOWN=0;
double UNCERTAIN_WHITE=0;
double UNCERTAIN_BLUE=0;
int BREAK_TIMES_BLUE=0;
bool GAP_WHITE=true;
string indicator_name="自定义/cz_笔_线段";
int    ExtLevel=3; // recounting's depth of extremums
int central_num_all=0;
//+------------------------------------------------------------------+
//| Expert initialization function         
//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }

void OnTick()
  {
   //RectangleDeleteAll();
   
   int ask_bid=0;
   int i=0,p=0;
   int ii=0;
   int rates_total=MathMin(Bars(Symbol(),0),recentKline);
   double zz[],line_segment_first[],line_segment_second[],line_segment_third[];
   int zz_num=0,segment_num=0,segment_second_num=0,segment_third_num=0;
   double Leg[]; 
   int Leg_idx[];
   double segment_value[];
   int segment_value_index[];
   double segment_second_value[];
   int segment_second_value_index[];
   double segment_third_value[];
   int segment_third_value_index[];

   ArrayResize(line_segment_first,1);
   GegSegment(rates_total,Leg,Leg_idx,segment_value,segment_value_index,segment_second_value,segment_second_value_index,
               segment_third_value,segment_third_value_index,zz,line_segment_first,line_segment_second,line_segment_third,
               zz_num,segment_num,segment_second_num,segment_third_num);
   if(UNCERTAIN_BLUE!=line_segment_first[0]&&line_segment_first[0]!=0)
     {
      PrintFormat("up:%s,down:%s,trend_blue:%s,trend_white:%s,trend_green:%s,ratio:%s,uncer_white:%s,uncer_blue:%s",DoubleToStr(RECENT_CENTRAL_EDGE_UP),
      DoubleToStr(RECENT_CENTRAL_EDGE_DOWN),IntegerToString(TREND_BLUE),IntegerToString(TREND_WHITE),IntegerToString(TREND_GREEN),
      DoubleToStr(RATIO_BLUE),DoubleToStr(UNCERTAIN_WHITE),DoubleToStr(UNCERTAIN_BLUE));
     }
   double buyop=0,buylots=0;
   double sellop=0,selllots=0;
   bool gap_blue=true,gap_green=true;
   double second_high2=0,second_low2=0;

   if(buydanshu(Symbol(),Magic,buyop,buylots)>0)
     {
      if(CloseLimit(ModeClose)==true && TREND_WHITE==1)
        {
         closebuy(Symbol(),Magic,Slip);
         printf("蓝线中枢背离");
         SendNotification(Symbol()+": 平多头仓 原因：蓝线中枢背离");
        }
      else if(TREND_WHITE==1)
        {
         if(line_segment_second[0]<UNCERTAIN_WHITE && line_segment_second[0]!=0)
           {
            closebuy(Symbol(),Magic,Slip);
            printf("白线反转平仓");
            SendNotification(Symbol()+": 平空头仓 原因：白线反转");
           }
        }
     }
   else if(selldanshu(Symbol(),Magic,sellop,selllots)>0)
     {
      if(CloseLimit(ModeClose)==true && TREND_WHITE==-1)
        {
         closesell(Symbol(),Magic,Slip);
         printf("蓝线中枢背离");
         SendNotification(Symbol()+": 平空头仓 原因：蓝线中枢背离");
        }
      else if(TREND_WHITE==-1)
        {
         if(line_segment_second[0]>UNCERTAIN_WHITE)
           {
            closesell(Symbol(),Magic,Slip);
            printf("白线反转平仓");
            SendNotification(Symbol()+": 平空头仓 原因：白线反转");
           }
        }
     }
   else if(TREND_BLUE==TREND_WHITE)
     {
      if(UNCERTAIN_WHITE>RECENT_CENTRAL_EDGE_UP && UNCERTAIN_BLUE>UNCERTAIN_WHITE && TREND_BLUE==-1)
         {
          if(OpenBuyLimit(ModeOpen)==true)
            {
             if(line_segment_first[0]>UNCERTAIN_BLUE)
               {
                StopLoss=segment_value[1];
                if(buydanshu(Symbol(),Magic,buyop,buylots)>0)closesell(Symbol(),Magic,Slip);
                if(Ask-StopLoss<=Point*MaxStopLoss)
                  {
                   buy(Lots,Slip,StopLoss,0,"long",Magic);
                   SendNotification(Symbol()+": 做多 原因：三类买点");
                  }
               }
            }
         }
       else if(UNCERTAIN_WHITE<RECENT_CENTRAL_EDGE_DOWN && UNCERTAIN_BLUE<UNCERTAIN_WHITE && TREND_BLUE==1)
         {
          if(OpenSellLimit(ModeOpen)==TRUE)
            {
             if(line_segment_first[0]!=0 && line_segment_first[0]<UNCERTAIN_BLUE)
               {
                StopLoss=segment_value[1];
                if(selldanshu(Symbol(),Magic,sellop,selllots)>0)closebuy(Symbol(),Magic,Slip);
                if(StopLoss-Bid<=Point*MaxStopLoss)
                  {
                   sell(Lots,Slip,StopLoss,0,"short",Magic);
                   SendNotification(Symbol()+": 做空 原因：三类卖点");
                  }
               }
            }
         }
     }
   
   double in=0,out=0;

   UNCERTAIN_BLUE=segment_value[0];
   UNCERTAIN_WHITE=segment_second_value[0];
   if(segment_num>0)
     {
      if(segment_value[0]>segment_value[1])TREND_BLUE=1;
      else if(segment_value[0]<segment_value[1])TREND_BLUE=-1;
     }
   if(segment_second_num>0)
     {
      if(segment_second_value[0]>segment_second_value[1])TREND_WHITE=1;
      else if(segment_second_value[0]<segment_second_value[1])TREND_WHITE=-1;
     }
   if(segment_third_num>0)
     {
      if(segment_third_value[0]>segment_third_value[1])TREND_GREEN=1;
      else if(segment_third_value[0]<segment_third_value[1])TREND_GREEN=-1;
     }
   double up=0,down=0;
   if(segment_num>0)
     {
      CENTRAL_RED_NUM=DrawnCentral(TREND_BLUE,1,rates_total,segment_value_index[1],Leg,
                                Leg_idx,zz_num+1,Period(),up,down,in,out);//二级中枢   
      if(segment_num>3)
        {
         RATIO_BLUE=GetRatio(segment_value_index[0],segment_value_index[1],segment_value_index[2],segment_value_index[3],
         segment_value[0],segment_value[1],segment_value[2],segment_value[3]);
        }
     }
   if(segment_second_num>0)
     {
      CENTRAL_BLUE_NUM=DrawnCentral(TREND_WHITE,2,rates_total,segment_second_value_index[1],segment_value,
                                segment_value_index,segment_num+1,Period(),up,down,DISTENCE_IN_BLUE,DISTENCE_OUT_BLUE);//二级中枢
     }
   if(segment_third_num>0)
     {
      DrawnCentral(TREND_GREEN,3,rates_total,segment_third_value_index[1],segment_second_value,
                                segment_second_value_index,segment_second_num+1,Period(),RECENT_CENTRAL_EDGE_UP,RECENT_CENTRAL_EDGE_DOWN,in,out);//三级中枢
     }
  }
bool CloseLimit(int mode_close)
  {
   if(mode_close==0)
     {
      if(CENTRAL_BLUE_NUM>=2 && DiverMethod(Method,DISTENCE_IN_BLUE,DISTENCE_OUT_BLUE,RATIO_BLUE,RATIO_BLUE_PARA)==TRUE)return true;
     }
   if(mode_close==2)
     {
      if(CENTRAL_BLUE_NUM>=2)return true;
     }
   if(mode_close==1)
     {
      if(DiverMethod(Method,DISTENCE_IN_BLUE,DISTENCE_OUT_BLUE,RATIO_BLUE,RATIO_BLUE_PARA)==TRUE)return true;
     }
   if(mode_close==3)return true;
   return false;
  }
bool OpenBuyLimit(int mode)
  {
   bool case1=(TREND_GREEN==1);
   bool case2=(GAP_WHITE==FALSE || BREAK_TIMES_BLUE==1);
   bool case3=(CENTRAL_BLUE_NUM>=2);
   bool case4=(DiverMethod(Method,DISTENCE_IN_BLUE,DISTENCE_OUT_BLUE,RATIO_BLUE,RATIO_BLUE_PARA)==TRUE);
   if(TREND_WHITE==-1)
     {
      if(mode==0){if(case1 && (case2 || (case3 && case4)))return true;}
      if(mode==1){if(case2 || (case3 && case4))return true;}
      if(mode==2){if(case2 && case3 && case4)return true;}
      if(mode==3){if(case3 && case4)return true;}
      if(mode==4){if(case2 && case3)return true;}
      if(mode==5){if(case2 && case4)return true;}
      if(mode==6){if(case2 && (case3 || case4))return true;}
      if(mode==7){if(case3)return true;}
      if(mode==8){if(case4)return true;}
      if(mode==9){if(case2)return true;}
      if(mode==10){if(case1)return true;}
      if(mode==11){if((case2 || (case3 && case4)) && case1)return true;}
      if(mode==12){if(case2 && case3 && case4 && case1)return true;}
      if(mode==13){if(case3 && case4 && case1)return true;}
      if(mode==14){if(case2 && case3 && case1)return true;}
      if(mode==15){if(case2 && case4 && case1)return true;}
      if(mode==16){if(case2 && (case3 || case4) && case1)return true;}
      if(mode==17){if(case3 && case1)return true;}
      if(mode==18){if(case4 && case1)return true;}
      if(mode==19){if(case2 && case1)return true;}
      if(mode==20)return true;
     }
   return false;        
  }

bool OpenSellLimit(int mode)
  {
   bool case1=(TREND_GREEN==-1);
   bool case2=(GAP_WHITE==FALSE || BREAK_TIMES_BLUE==1);
   bool case3=(CENTRAL_BLUE_NUM>=2);
   bool case4=(DiverMethod(Method,DISTENCE_IN_BLUE,DISTENCE_OUT_BLUE,RATIO_BLUE,RATIO_BLUE_PARA)==TRUE);
   if(TREND_WHITE==1)
     {
      if(mode==0){if(case1 && (case2 || (case3 && case4)))return true;}
      if(mode==1){if(case2 || (case3 && case4))return true;}
      if(mode==2){if(case2 && case3 && case4)return true;}
      if(mode==3){if(case3 && case4)return true;}
      if(mode==4){if(case2 && case3)return true;}
      if(mode==5){if(case2 && case4)return true;}
      if(mode==6){if(case2 && (case3 || case4))return true;}
      if(mode==7){if(case3)return true;}
      if(mode==8){if(case4)return true;}
      if(mode==9){if(case2)return true;}
      if(mode==10){if(case1)return true;}
      if(mode==11){if((case2 || (case3 && case4)) && case1)return true;}
      if(mode==12){if(case2 && case3 && case4 && case1)return true;}
      if(mode==13){if(case3 && case4 && case1)return true;}
      if(mode==14){if(case2 && case3 && case1)return true;}
      if(mode==15){if(case2 && case4 && case1)return true;}
      if(mode==16){if(case2 && (case3 || case4) && case1)return true;}
      if(mode==17){if(case3 && case1)return true;}
      if(mode==18){if(case4 && case1)return true;}
      if(mode==19){if(case2 && case1)return true;}
      if(mode==20)return true;
     }
   return false;        
  }
void GegSegment(int rates_total,double &Leg[],int &Leg_idx[],double &segment_value[],int &segment_value_index[],double &segment_second_value[],int &segment_second_value_index[],
               double &segment_third_value[],int &segment_third_value_index[],double &zz[],double &line_segment_first[],double &line_segment_second[],double &line_segment_third[],
               int &zz_num,int &segment_num,int &segment_second_num,int &segment_third_num)
  {
   ArrayResize(Leg_idx,rates_total);
   ArrayResize(segment_value_index,rates_total);
   ArrayResize(segment_second_value_index,rates_total);
   ArrayResize(segment_third_value_index,rates_total);
   ArrayResize(segment_third_value,rates_total);
   ArrayResize(segment_second_value,rates_total);
   ArrayResize(segment_value,rates_total);
   ArrayResize(Leg,rates_total);
   ArrayInitialize(zz,0.0);
   ArrayResize(zz,rates_total);
   ArrayInitialize(line_segment_first,0.0);
   ArrayResize(line_segment_first,rates_total);
   ArrayInitialize(line_segment_second,0.0);
   ArrayResize(line_segment_second,rates_total);
   ArrayInitialize(line_segment_third,0.0);
   ArrayResize(line_segment_third,rates_total);
   int i=0;
   for(i=0;i<rates_total;i++)
     {
      zz[i]=iCustom(NULL,0,indicator_name,0,i);
      if(zz[i]!=0)
        {
         Leg[zz_num]=zz[i];
         Leg_idx[zz_num]=i;
         zz_num++;
         line_segment_first[i]=iCustom(NULL,0,indicator_name,1,i);
         if(line_segment_first[i]!=0)
           {
            segment_value[segment_num]=line_segment_first[i];
            segment_value_index[segment_num]=i;
            segment_num++;
            line_segment_second[i]=iCustom(NULL,0,indicator_name,2,i);
            if(line_segment_second[i]!=0)
              {
               segment_second_value[segment_second_num]=line_segment_second[i];
               segment_second_value_index[segment_second_num]=i;
               segment_second_num++;
               line_segment_third[i]=iCustom(NULL,0,indicator_name,3,i);
               if(line_segment_third[i]!=0)
                 {
                  segment_third_value[segment_third_num]=line_segment_third[i];
                  segment_third_value_index[segment_third_num]=i;
                  segment_third_num++;
                  if(segment_third_num>=2)break;
                 }
              }
           }
        }
     }
   ArrayResize(zz,i+1);
   ArrayResize(line_segment_first,i+1);
   ArrayResize(line_segment_second,i+1);
   ArrayResize(line_segment_third,i+1);
   ArrayResize(Leg,zz_num);
   ArrayResize(Leg_idx,zz_num);
   ArrayResize(segment_value,segment_num);
   ArrayResize(segment_value_index,segment_num);
   ArrayResize(segment_second_value,segment_second_num);
   ArrayResize(segment_second_value_index,segment_second_num);
   ArrayResize(segment_third_value,segment_third_num);
   ArrayResize(segment_third_value_index,segment_third_num);
  }
double GetRatio(int segment_value_index_num0,int segment_value_index_num1,int segment_value_index_num2,int segment_value_index_num3,
                double segment_value_num0,double segment_value_num1,double segment_value_num2,double segment_value_num3)
  {
   double angle1=MathAbs((segment_value_num1-segment_value_num0)/(segment_value_index_num1-segment_value_index_num0));
   double angle2=MathAbs((segment_value_num3-segment_value_num2)/(segment_value_index_num3-segment_value_index_num2));
   return angle1/angle2;
  }
//+------------------------------------------------------------------+
//|   画出最新线段的中枢                                             |
//+------------------------------------------------------------------+
int DrawnCentral(int trend,int rank,int rates_total,int segment_value_index_num1,double &leg[],
                 int &leg_idx[],int k,int period,double &central_up,double &central_down,double &distance_in,double &distance_out)
  {
   color col;
   if(rank==1)col=clrRed;
   else if(rank==2)col=clrDarkTurquoise;
   else col=clrYellow;
   central_up=10000000;
   central_down=0;
   int kk=0,i=0,j=0;
   distance_in=0;
   distance_out=0;
   for(kk=0;kk<k;kk++)
     {
      if(leg_idx[kk]==segment_value_index_num1)
        {
         break;
        }
     }
   
   int b=kk;
   int central_num=0;

   double last_up=0,last_down=100000000,new_down=0,new_up=0;
   if(b<=4)return 0;

   for(j=kk;j>=0;j--)
     {
      if(b<4)break;
      for(i=b;i>=4;i--)
        { 
         //printf(i);
         if(leg[i]>leg[i-1] && trend==1)
           {
            new_up=MathMin(leg[i],leg[i-2]);
            new_down=MathMax(leg[i-1],leg[i-3]);
            if(new_up<=new_down)continue;
            if(new_up>new_down && (new_down>last_up || new_up<last_down))
              {
               last_up=new_up;
               last_down=new_down;
               //RectangleCreate(0,"rectangle_"+IntegerToString(period)+"_"+IntegerToString(rank)+"_"+IntegerToString(central_num_all),
                 //              0,Time[leg_idx[i]],new_up,Time[leg_idx[i-3]],new_down,col,STYLE_SOLID,3,false,false,false,false,0);
               
               central_num++;
               central_num_all++;
               central_up=last_up;
               central_down=last_down;
               if(leg[i]>leg[i-1])
                {
                 if(i>0)distance_in=(new_down+new_up)/2-leg[i+1];
                 distance_out=leg[i-4]-(new_down+new_up)/2;
                }
               if(leg[i]<leg[i-1])
                 {
                  distance_in=(new_down+new_up)/2-leg[i];
                  distance_out=leg[i-3]-(new_down+new_up)/2;
                 }  
               b=i-4;
               break;
              }
           }
         else if(leg[i]<leg[i-1] && trend==-1)
           {
            new_up=MathMin(leg[i-1],leg[i-3]);
            new_down=MathMax(leg[i],leg[i-2]);
            if(new_up<=new_down)continue;
            if(new_up>new_down && (new_down>last_up || new_up<last_down))
              {
               last_up=new_up;
               last_down=new_down;
               //RectangleCreate(0,"rectangle_"+IntegerToString(period)+"_"+IntegerToString(rank)+"_"+IntegerToString(central_num_all),
                 //              0,Time[leg_idx[i]],new_up,Time[leg_idx[i-3]],new_down,col,STYLE_SOLID,3,false,false,false,false,0);
               central_num_all++;
               central_num++;
               central_up=last_up;
               central_down=last_down;

               if(leg[i]<leg[i-1])
                {
                 distance_in=leg[i+1]-(new_down+new_up)/2;
                 distance_out=(new_down+new_up)/2-leg[i-4];
                }
               if(leg[i]>leg[i+1])
                 {
                  distance_in=leg[i]-(new_down+new_up)/2;
                  distance_out=(new_down+new_up)/2-leg[i-3];
                 }
               b=i-4;
               break;
              }
           }
        }
     }
   return(central_num);
  }
void RectangleDeleteAll()
  {
   string s;
   int k=ObjectsTotal();
   if(k>0)
     {
      for(int i=k-1;i>=0;i--)
        {
         s=ObjectName(i);
         ObjectDelete(s);
        }
     }
  }
bool RectangleCreate(const long            chart_ID=0,        // chart's ID 
                     const string          name="Rectangle",  // rectangle name 
                     const int             sub_window=0,      // subwindow index  
                     datetime              time1=0,           // first point time 
                     double                price1=0,          // first point price 
                     datetime              time2=0,           // second point time 
                     double                price2=0,          // second point price 
                     const color           clr=clrRed,        // rectangle color 
                     const ENUM_LINE_STYLE style=STYLE_SOLID, // style of rectangle lines 
                     const int             width=1,           // width of rectangle lines 
                     const bool            fill=false,        // filling rectangle with color 
                     const bool            back=false,        // in the background 
                     const bool            selection=true,    // highlight to move 
                     const bool            hidden=true,       // hidden in the object list 
                     const long            z_order=0)         // priority for mouse click 
  {
//--- set anchor points' coordinates if they are not set 
   ChangeRectangleEmptyPoints(time1,price1,time2,price2);
//--- reset the error value 
   ResetLastError();
//--- create a rectangle by the given coordinates 
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE,sub_window,time1,price1,time2,price2))
     {

      Print(__FUNCTION__,
            ": failed to create a rectangle! Error code = ",GetLastError());

      return(false);
     }
//--- set rectangle color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set the style of rectangle lines 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set width of the rectangle lines 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- enable (true) or disable (false) the mode of filling the rectangle 
   ObjectSetInteger(chart_ID,name,OBJPROP_FILL,fill);
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of highlighting the rectangle for moving 
//--- when creating a graphical object using ObjectCreate function, the object cannot be 
//--- highlighted and moved by default. Inside this method, selection parameter 
//--- is true by default making it possible to highlight and move the object 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution 
   return(true);
  }
void ChangeRectangleEmptyPoints(datetime &time1,double &price1,
                                datetime &time2,double &price2)
  {
//--- if the first point's time is not set, it will be on the current bar 
   if(!time1)
      time1=TimeCurrent();
//--- if the first point's price is not set, it will have Bid value 
   if(!price1)
      price1=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- if the second point's time is not set, it is located 9 bars left from the second one 
   if(!time2)
     {
      //--- array for receiving the open time of the last 10 bars 
      datetime temp[10];
      CopyTime(Symbol(),Period(),time1,10,temp);
      //--- set the second point 9 bars left from the first one 
      time2=temp[0];
     }
//--- if the second point's price is not set, move it 300 points lower than the first one 
   if(!price2)
      price2=price1-300*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
  }
//+-----------------------------------------------------------------------+
//|获取各个级别最终趋势                                                   |
//+-----------------------------------------------------------------------+
int buy(double lots,int slip,double sl,double tp,string com,int buymagic)
  {
    int a=0;
    bool zhaodan=false;
    for(int i=0;i<OrdersTotal();i++)
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
    for(int i=0;i<OrdersHistoryTotal();i++)
      {
        if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true)
          {
            int ma=OrderMagicNumber();
            datetime t=OrderCloseTime();
            if(OrderSymbol()==Symbol() && Time[0]-t<Period()*6*60 && ma==buymagic)
              {
                zhaodan=true;
                break;
              }
          }
      }
    if(zhaodan==false)
      {
        a=OrderSend(Symbol(),OP_BUY,lots,Ask,slip,
        NormalizeDouble(MathMin(sl,Bid-Point*MarketInfo(Symbol(),MODE_STOPLEVEL)),Digits),tp,com,buymagic,0,Red);
      }
    return(a);
  }
int sell(double lots,int slip,double sl,double tp,string com,int sellmagic)
  {
    int a=0;
    bool zhaodan=false;
    for(int i=0;i<OrdersTotal();i++)
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
    for(int i=0;i<OrdersHistoryTotal();i++)
      {
        if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true)
          {
            int ma=OrderMagicNumber();
            datetime t=OrderCloseTime();
            
            if(OrderSymbol()==Symbol() && Time[0]-t<Period()*6*60 && ma==sellmagic)
              {
                zhaodan=true;
                break;
              }
          }
      }
    if(zhaodan==false)
      {
        a=OrderSend(Symbol(),OP_SELL,lots,Bid,slip,
        NormalizeDouble(MathMax(sl,Ask+Point*MarketInfo(Symbol(),MODE_STOPLEVEL)),Digits),tp,com,sellmagic,0,Green);
      }
    return(a);
  }

//+------------------------------------------------------------------------------------------+
//| 判断进出中枢距离和角度是否背驰，method（0：距离背驰，1：角度背驰，2：距离角度同时背驰）  |                                        |
//+------------------------------------------------------------------------------------------+
bool DiverMethod(int method,double distance_in,double distance_out,double ratio,double ratio_para)
  {
   if(method==0)//距离和角度背驰
     {
      if(DiverDistance(distance_in,distance_out)==true && 
         DiverAngleRatio(ratio,ratio_para)==true)return true;
     }
   if(method==1)//角度背驰
     {
      if(DiverAngleRatio(ratio,ratio_para)==true)return true;
     }
   if(method==2)//距离背驰
     {
      if(DiverDistance(distance_in,distance_out)==true)return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| 判断进出中枢距离是否背驰，rank{3：白线笔，2：蓝线笔，1：紫线笔}  |                                      |
//+------------------------------------------------------------------+
bool DiverDistance(double distance_in,double distance_out )
  {
   if(distance_out<distance_in)return true;
   else return false;
  }
//+------------------------------------------------------------------+
//| 判断进出中枢角度是否背驰，rank{3：白线笔，2：蓝线笔，1：紫线笔}  |                                      |
//+------------------------------------------------------------------+
bool DiverAngleRatio(double ratio,double ratio_para)
  {
   if(ratio<ratio_para)return true;
   else return false;
  }

void closebuy(string symbol,int magic,int slip)
  { 
    double buyop,buylots;
    bool a;
    bool b=true;
    while(buydanshu(symbol,magic,buyop,buylots)>0 && b==true)
     {
        int t=OrdersTotal();
        for(int i=t-1;i>=0;i--)
         {
           if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
             {
               if(OrderSymbol()==symbol && OrderType()==OP_BUY && OrderMagicNumber()==magic)
                 {
                  if(Time[0]-OrderOpenTime()>Period()*60*6)
                   {
                    a=OrderClose(OrderTicket(),OrderLots(),Bid,slip,White);
                   }
                  else b=false;
                    
                 }
             }
         }
        Sleep(800);
     }
  }
void closesell(string symbol,int magic,int slip)
  {
    double sellop,selllots;
    bool a;
    bool b=true;
    while(selldanshu(symbol,magic,sellop,selllots)>0 && b==true)
     {
        int t=OrdersTotal();
        for(int i=t-1;i>=0;i--)
         {
           if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
             {
               if(OrderSymbol()==symbol && OrderType()==OP_SELL && OrderMagicNumber()==magic)
                 {
                  if(Time[0]-OrderOpenTime()>Period()*60*6)
                   {
                    a=OrderClose(OrderTicket(),OrderLots(),Ask,slip,White);
                   }
                  else b=false;
                 }
             }
         }
        Sleep(800);
     }
  }
void buyxiugaitp(double tp,int magic)
  {
     bool a;
     for(int i=0;i<OrdersTotal();i++)
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
void sellxiugaitp(double tp,int magic)
  {
     bool a;
     for(int i=0;i<OrdersTotal();i++)
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
double avgbuyprice(int magic)
  {
    double a=0;
    int shuliang=0;
    double pricehe=0;
    for(int i=0;i<OrdersTotal();i++)
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
double avgsellprice(int magic)
  {
    double a=0;
    int shuliang=0;
    double pricehe=0;
    for(int i=0;i<OrdersTotal();i++)
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
double flots(double dlots)
  {
    double fb=NormalizeDouble(dlots/MarketInfo(Symbol(),MODE_MINLOT),0);
    return(MarketInfo(Symbol(),MODE_MINLOT)*fb);
  }
int buydanshu(string symbol,int magic,double &op,double &lots)
  {
     int a=0;
     op=0;
     lots=0;
     for(int i=0;i<OrdersTotal();i++)
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
int selldanshu(string symbol,int magic,double &op,double &lots)
  {
     int a=0;
     op=0;
     lots=0;
     for(int i=0;i<OrdersTotal();i++)
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