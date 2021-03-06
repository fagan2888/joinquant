//+------------------------------------------------------------------+
//|                                         chanlun_basecz.mq4       |
//|                            做蓝线的二类买卖点；目的：获取蓝线一笔|
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

extern double Lots=0.1;//下单量
extern int Slip=50;//滑点
extern double StopLoss=0;//止损点
extern int TakeProfit=1;//止盈倍数
extern int    recentKline=20000;//计算最近K线数目
input  int    Method=0;//背离判断条件
input int ModeOpen=0;//开仓过滤条件（0-19）
input int ModeClose=0;//平仓过滤条件（0-2）
input double RATIO_RED_PARA=1;//二级别进中枢出中枢效率参数
extern int Magic=1;
input int MaxStopLoss=10000;     // 最大止损点
//+------------------------------------------------------------------+
//| 全局变量                                                         |  
int CENTRAL_BLUE_NUM=0;//二级别中枢个数
int CENTRAL_RED_NUM=0;//一级别中枢个数
double DISTENCE_IN_RED=0;//二级别进入中枢距离
double DISTENCE_OUT_RED=100000;//二级别出中枢距离
double RATIO_RED=1;//二级别进中枢出中枢效率
int TREND_RED=0;//红线趋势方向
int TREND_WHITE=0;//白线趋势方向
int TREND_BLUE=0;//蓝线趋势方向
double UNCERTAIN_RED=0;//最后一个不确定的红线的值
double UNCERTAIN_BLUE=0;//最后一个不确定的蓝线的值
bool GAP_BLUE=true;//判断蓝线反转时是否有缺口
int BREAK_TIMES_RED=0;//判断蓝线反转时有缺口情况下红线突破次数
int    ExtLevel=3; // recounting's depth of extremums
string name="自定义/cz_笔_0729";//调用指标笔的名称
//+------------------------------------------------------------------+
//| Expert initialization function         
//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   int rates_total=MathMin(Bars(Symbol(),0),recentKline);//计算的K线数
   double zz[];//笔
   ArrayInitialize(zz,0.0);
   ArrayResize(zz,rates_total);
   GetZigZagNumber(rates_total,zz);//创建笔
   int k=0;//zigzag高低点个数
   double Leg[];
   int Leg_idx[];
   CreateLegs(rates_total,k,Leg,Leg_idx,zz);//根据zigzag值创建原始笔、原始笔位置、原始笔数目k
   int segment_num=0;//一级线段点的个数
   double segment_value[];//一级线段高低点值
   int segment_value_index[];//一级线段高低点位置
   double second_high1=0,second_low1=0;//一级线段次高点、次低点
   double buyop=0,buylots=0;//持仓多头单信息
   double sellop=0,selllots=0;//持仓空头单信息
   bool gap_white=true;//白线是否有缺口
   int break_times_blue=0;//白线有缺口时，蓝线突破次数
   int k_second=0;//一级线段高低点个数
   int segment_second_num=0;//二级线段点的个数
   double segment_second_value[];//二级线段高低点值
   int segment_second_value_index[];//二级线段高低点位置
   double second_high2=0,second_low2=0;//二级线段次高点、次低点
   if(buydanshu(Symbol(),Magic,buyop,buylots)>0)//是否存在多头持仓
     {
      if(CloseLimit(ModeClose)==true && TREND_BLUE==1)//判断是否满足平仓条件-：红线向上两个中枢且中枢背离
        {
         if(Leg[k-1]<Leg[k-2])//红线最后一笔向下，目的：背离确认
           {
            closebuy(Symbol(),Magic,Slip);
            Alert("红线中枢背离");
            SendNotification(Symbol()+": 平多头仓 原因：红线中枢背离");
           }
        }
      else if(TREND_BLUE==1)//判断是否满足平仓条件二：蓝线反转
        {
         CreateSegments(GAP_BLUE,BREAK_TIMES_RED,TREND_BLUE,segment_num,Leg,Leg_idx,segment_value,segment_value_index,k,second_high1,second_low1);//创建一级线段
         if(TREND_BLUE==-1)
           {
            closebuy(Symbol(),Magic,Slip);
            printf("蓝线反转平仓");
            SendNotification(Symbol()+": 平空头仓 原因：蓝线反转");
           }

        }
     }
   else if(selldanshu(Symbol(),Magic,sellop,selllots)>0)//是否存在空头持仓
     {
      if(CloseLimit(ModeClose)==true && TREND_BLUE==-1)//判断是否满足平仓条件-：红线向下两个中枢且中枢背离
        {
         if(Leg[k-1]>Leg[k-2])//红线最后一笔向上，目的：背离确认
           {
            Alert("红线中枢背离");
            closesell(Symbol(),Magic,Slip);
            SendNotification(Symbol()+": 平空头仓 原因：红线中枢背离");
           }
        }
      else if(TREND_BLUE==-1)//判断是否满足平仓条件二：蓝线反转
        {
         CreateSegments(GAP_BLUE,BREAK_TIMES_RED,TREND_BLUE,segment_num,Leg,Leg_idx,segment_value,segment_value_index,k,second_high1,second_low1);//创建一级线段
         if(TREND_BLUE==1)
           {
            closesell(Symbol(),Magic,Slip);
            printf("蓝线反转平仓");
            SendNotification(Symbol()+": 平空头仓 原因：蓝线反转");
           }
        }
     }
   else if(TREND_BLUE==TREND_RED && CENTRAL_BLUE_NUM<2)//开仓必备条件：蓝线最新趋势方向和红线趋势方向一致且蓝线中枢小于2
     {
      if(UNCERTAIN_RED>UNCERTAIN_BLUE)//二类买点开仓必备条件：红线最新低点大于蓝线最新低点
        {
         if(OpenBuyLimit(ModeOpen)==true)//买入开仓必备条件：白线趋势向上、蓝线趋势向下、红线向下两个中枢且发生背离、蓝线无缺口或有缺口且红线完成一次突破
           {
            if(Leg[k-1]>Leg[k-2])//红线最后一笔向上，前低点确认
              {
               Alert("红线中枢背离");
               StopLoss=Leg[k-2];
               double takeProfit=Ask+TakeProfit*(Leg[k-1]-StopLoss);
               if(buydanshu(Symbol(),Magic,buyop,buylots)>0)closesell(Symbol(),Magic,Slip);
               if(Ask-StopLoss<=Point*MaxStopLoss)//止损位小于设定参数
                 {
                  buy(Lots,Slip,StopLoss,takeProfit,"long",Magic);//止盈
                  SendNotification(Symbol()+": 做多 原因：三类买点");
                 }
              }
           }
        }
      else if(UNCERTAIN_RED<UNCERTAIN_BLUE)//二类卖点开仓必备条件：红线最新高点小于蓝线最新高点
        {
         if(OpenSellLimit(ModeOpen)==TRUE)//卖出开仓必备条件：白线趋势向下、蓝线趋势向上、红线向上两个中枢且发生背离、蓝线无缺口或有缺口且红线完成一次突破
           {
            if(Leg[k-1]<Leg[k-2])//红线最后一笔向下，前高点确认
              {
               Alert("红线中枢背离");
               StopLoss=Leg[k-2];
               double takeProfit=Bid-TakeProfit*(StopLoss-Leg[k-1]);
               if(selldanshu(Symbol(),Magic,sellop,selllots)>0)closebuy(Symbol(),Magic,Slip);
               if(StopLoss-Bid<=Point*MaxStopLoss)//止损位小于设定参数
                 {
                  sell(Lots,Slip,StopLoss,takeProfit,"short",Magic);
                  SendNotification(Symbol()+": 做空 原因：三类卖点");
                 }
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
   UNCERTAIN_BLUE=segment_value[segment_num];//蓝线最新线段点
   UNCERTAIN_RED=Leg[k-1];//红线最新线段点
   double up=0,down=0;//最新中枢的上沿和下沿
   if(k>4)
     {
      RATIO_RED=GetRatio(Leg_idx[k-1],Leg_idx[k-2],Leg_idx[k-3],Leg_idx[k-4],Leg[k-1],Leg[k-2],Leg[k-3],Leg[k-4]);//红线最新角度效率值
      if(Leg[k-1]>Leg[k-2])TREND_RED=1;//红线最新趋势
      else TREND_RED=-1;
     }
   if(segment_num>0)
     {
      CENTRAL_RED_NUM=DrawnCentral(TREND_BLUE,1,rates_total,segment_value_index[segment_num-1],Leg,
                                   Leg_idx,k,Period(),up,down,DISTENCE_IN_RED,DISTENCE_OUT_RED);//获取红线中枢个数并计算进出中枢距离   

     }
  }
//+------------------------------------------------------------------+
//|     平仓条件限制：红线中枢大于等于2且发生中枢背离                |
//+------------------------------------------------------------------+
bool CloseLimit(int mode_close)
  {
   if(mode_close==0)
     {
      if(CENTRAL_RED_NUM>=2 && DiverMethod(Method,DISTENCE_IN_RED,DISTENCE_OUT_RED,RATIO_RED,RATIO_RED_PARA)==TRUE)
        {
         
         return true;
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
//|     买入开仓条件限制： 白线方向向上，红线向下两个中枢且中枢背离  |
//+------------------------------------------------------------------+
bool OpenBuyLimit(int mode)
  {
   bool case1=(TREND_WHITE==1);
   bool case2=(GAP_BLUE==FALSE || BREAK_TIMES_RED==1);//没有缺口或者有缺口但已经完成一次突破
   bool case3=(CENTRAL_RED_NUM>=2);
   bool case4=(DiverMethod(Method,DISTENCE_IN_RED,DISTENCE_OUT_RED,RATIO_RED,RATIO_RED_PARA)==TRUE);
   if(TREND_BLUE==-1)
     {
      if(mode==0){if(case1 && (case2 && (case3 && case4)))return true;}
     }
   
   return false;
  }
//+------------------------------------------------------------------+
//|    卖出开仓条件限制： 白线方向向下，红线向上两个中枢且中枢背离   |
//+------------------------------------------------------------------+
bool OpenSellLimit(int mode)
  {
   bool case1=(TREND_WHITE==-1);
   bool case2=(GAP_BLUE==FALSE || BREAK_TIMES_RED==1);//没有缺口或者有缺口但已经完成一次突破
   bool case3=(CENTRAL_RED_NUM>=2);
   bool case4=(DiverMethod(Method,DISTENCE_IN_RED,DISTENCE_OUT_RED,RATIO_RED,RATIO_RED_PARA)==TRUE);
   if(TREND_BLUE==1)
     {
      if(mode==0){if(case1 && (case2 && (case3 && case4)))return true;}
     }
   return false;
  }
//+------------------------------------------------------------------+
//|    获取角度效率比值                                              |
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
   distance_in=0;//进中枢距离
   distance_out=0;//出中枢距离
   for(kk=k-1;kk>=0;kk--)
     {
      if(leg_idx[kk]==segment_value_index_num1)
        {
         break;
        }
     }
   int b=kk;
   int central_num=0,central_num_all=0;

   double last_up=0,last_down=100000000,new_down=0,new_up=0;
   if(k-1-kk<=4)return 0;
   for(j=k-2;j>=kk;j--)
     {
      if(b>k-5)break;
      for(i=b;i<=k-5;i++)
        {
         if(leg[i]>leg[i+1] && trend==1)
           {
            new_up=MathMin(leg[i],leg[i+2]);
            new_down=MathMax(leg[i+1],leg[i+3]);
            if(new_up<=new_down)continue;
            if(new_up>new_down && (new_down>last_up || new_up<last_down))
              {
               last_up=new_up;
               last_down=new_down;
               central_num++;
               central_up=last_up;
               central_down=last_down;
               if(leg[i]>leg[i+1])
                 {
                  if(i>0)distance_in=(new_down+new_up)/2-leg[i-1];
                  distance_out=leg[i+4]-(new_down+new_up)/2;
                 }
               if(leg[i]<leg[i+1])
                 {
                  distance_in=(new_down+new_up)/2-leg[i];
                  distance_out=leg[i+3]-(new_down+new_up)/2;
                 }
               b=i+4;
               break;
              }
           }
         else if(leg[i]<leg[i+1] && trend==-1)
           {
            new_up=MathMin(leg[i+1],leg[i+3]);
            new_down=MathMax(leg[i],leg[i+2]);
            if(new_up<=new_down)continue;
            if(new_up>new_down && (new_down>last_up || new_up<last_down))
              {
               last_up=new_up;
               last_down=new_down;
               central_num++;
               central_up=last_up;
               central_down=last_down;

               if(leg[i]<leg[i+1])
                 {
                  if(i>0)distance_in=leg[i-1]-(new_down+new_up)/2;
                  distance_out=(new_down+new_up)/2-leg[i+4];
                 }
               if(leg[i]>leg[i+1])
                 {
                  distance_in=leg[i]-(new_down+new_up)/2;
                  distance_out=(new_down+new_up)/2-leg[i+3];
                 }

               b=i+4;
               break;
              }
           }
        }
     }
   return(central_num);
  }
//+------------------------------------------------------------------------------------------+
//| 判断进出中枢距离和角度是否背驰，method（2：距离背驰，1：角度背驰，0：距离角度同时背驰）  |                                        |
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
//| 判断进出中枢距离是否背驰                                         |
//+------------------------------------------------------------------+
bool DiverDistance(double distance_in,double distance_out)
  {
   if(distance_out<distance_in)return true;
   else return false;
  }
//+------------------------------------------------------------------+
//| 判断角度是否背驰                                                 |
//+------------------------------------------------------------------+
bool DiverAngleRatio(double ratio,double ratio_para)
  {
   if(ratio<ratio_para)return true;
   else return false;
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
      for(d=b+1;d<k-3;d=d+2)//循环寻找是否需要重新确认低点
        {
         if(leg[d+2]<leg[d])break;
         if(leg[d+3]>leg[d+1])
           {
            if(leg[b+2]>=leg[b-1]){x=1;break;}
            else
              {
               a++;
               if(a==2){x=1;break;}
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
   else if(trend==-1)
     {
      for(d=b+1;d<k-3;d=d+2)//循环寻找是否需要重新确认低点
        {
         if(leg[d+2]>leg[d])break;
         if(leg[d+3]<leg[d+1])
           {
            if(leg[b+2]<=leg[b-1]){x=1;break;}
            else
              {
               a++;
               if(a==2){x=1;break;}
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
//| 根据笔初始三个点找到线段的第一个点                               |
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
   for(m=0;m<k-3;m++)//找出第一个线段趋势
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
         if(leg[b+1]<=second)gap=false;
        }
      for(i=b;i<k-2;i=i+2)
        {
         if(leg[i+2]>uncertain)//向上趋势再创新高
           {
            RenewUncertain(uncertain,uncertain_idx,
                           second,leg[i+2],leg_idx[i+2],i+2,b);
            break;
           }
         else//没有创新高，判断是否反转
           {
            if(i+3>=k)break;
            if(leg[i+3]<segment_value_num1 && leg[i+3]<leg[i+1]){x=1;break;}
            else if(leg[b+1]<=second) //无缺口，一次确认
              {

               if(leg[i+3]<leg[i+1]){x=1;break;}
              }
            else if(leg[i+3]<leg[i+1])//有缺口，需确认两次
              {
               break_num++;
               if(break_num==2){x=1;break;}
              }
           }
        }
     }
   if(trend==-1)
     {
      if(b+1<k)
        {
         if(leg[b+1]>=second)gap=false;
        }
      for(i=b;i<k-2;i=i+2)
        {
         if(leg[i+2]<uncertain)//向上趋势再创新高
           {
            RenewUncertain(uncertain,uncertain_idx,second,leg[i+2],leg_idx[i+2],i+2,b);
            break;
           }
         else//没有创新高，判断是否反转
           {
            if(i+3>=k)break;
            if(leg[i+3]>segment_value_num1 && leg[i+3]>leg[i+1]){x=1;break;}
            else if(leg[b+1]>=second) //无缺口，一次确认
              {
               if(leg[i+3]>leg[i+1]){x=1;break;}
              }
            else if(leg[i+3]>leg[i+1])//有缺口，需确认两次
              {
               break_num++;
               if(break_num==2){x=1;break;}
              }
           }
        }
     }
   return x;
  }
//+------------------------------------------------------------------+
//|  发生趋势反转进行新的线段点的确认                                |
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
   for(c=0;c<k-2;c++)
     {
      if(b+3>k)break;
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
         if(x==1)TrendTurn(trend,segment_value,segment_value_index,uncertain_high,
            uncertain_high_idx,uncertain_low,uncertain_low_idx,second_low,
            segment_num,leg[i+1],leg[i+3],leg_idx[i+3],i,b,e);
        }
      else if(trend==-1)
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

         if(x==1)TrendTurn(trend,segment_value,segment_value_index,uncertain_low,
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
      if(segment_value[segment_num-1]==Low[segment_value_index[segment_num-1]] && trend==1)
        {
         segment_value[segment_num]=uncertain_high;
         segment_value_index[segment_num]=uncertain_high_idx;
        }
      if(segment_value[segment_num-1]==High[segment_value_index[segment_num-1]] && trend==-1)
        {
         segment_value[segment_num]=uncertain_low;
         segment_value_index[segment_num]=uncertain_low_idx;
        }
     }
  }
//+------------------------------------------------------------------+
//|  根据笔的高低点计算线段                                          |
//+------------------------------------------------------------------+
int CreateSegments(bool &gap,int &break_num,int &trend,int &segment_num,double &leg[],int &leg_idx[],
                   double &segment_value[],int &segment_value_index[],int k,double &second_high,double &second_low)
  {
   ArrayResize(segment_value,MathMax(10,k));
   ArrayResize(segment_value_index,MathMax(10,k));
   ArrayInitialize(segment_value,0.0);
   ArrayInitialize(segment_value_index,0);
   if(k<5)return 0;
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
//|       创建笔的高低点函数                                         |
//+------------------------------------------------------------------+
void CreateLegs(int total,int &k,double &leg[],int &leg_idx[],double &buffer[])
  {
   k=0;
   ArrayInitialize(leg,0.0);
   ArrayInitialize(leg_idx,0);
   ArrayResize(leg,10000);
   ArrayResize(leg_idx,10000);
   int i=0;
   for(i=total-1;i>-1;i--)//zigzag的高低点
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
//|       调用笔的函数，即zigzag函数                                 |
//+------------------------------------------------------------------+

int GetZigZagNumber(const int rates_total,double &ExtZigzagBuffer[])
  {

   ArrayInitialize(ExtZigzagBuffer,0.0);
   ArrayResize(ExtZigzagBuffer,rates_total);
   for(int i=0;i<rates_total;i++)
     {
      ExtZigzagBuffer[i]=iCustom(NULL,0,name,0,i);
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|   多头平仓下单函数                                               |
//+------------------------------------------------------------------+
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
//+------------------------------------------------------------------+
//|          空头平仓下单函数                                        |
//+------------------------------------------------------------------+
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
//+------------------------------------------------------------------+
//|   帐户持有的多头单数                                             |
//+------------------------------------------------------------------+
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
//+------------------------------------------------------------------+
//|         帐户持有的空头单数                                       |
//+------------------------------------------------------------------+
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
//+-----------------------------------------------------------------------+
//|      买入下单函数                                                     |
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
                  NormalizeDouble(MathMin(sl,Bid-Point*MarketInfo(Symbol(),MODE_STOPLEVEL)),Digits),
                  NormalizeDouble(MathMax(tp,Ask+Point*MarketInfo(Symbol(),MODE_STOPLEVEL)),Digits),com,buymagic,0,Red);
      a=OrderSend(Symbol(),OP_BUY,lots,Ask,slip,
                  NormalizeDouble(MathMin(sl,Bid-Point*MarketInfo(Symbol(),MODE_STOPLEVEL)),Digits),
                  0,com,buymagic,0,Red);
     }
   return(a);
  }
//+------------------------------------------------------------------+
//|  卖出下单函数                                                    |
//+------------------------------------------------------------------+
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
                  NormalizeDouble(MathMax(sl,Ask+Point*MarketInfo(Symbol(),MODE_STOPLEVEL)),Digits),
                  NormalizeDouble(MathMin(tp,Bid-Point*MarketInfo(Symbol(),MODE_STOPLEVEL)),Digits),com,sellmagic,0,Green);
      a=OrderSend(Symbol(),OP_SELL,lots,Bid,slip,
                  NormalizeDouble(MathMax(sl,Ask+Point*MarketInfo(Symbol(),MODE_STOPLEVEL)),Digits),
                  0,com,sellmagic,0,Green);
     }
   return(a);
  }