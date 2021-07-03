module cmos_capture_data(
    input                 rst_n           ,  //复位信号
    //摄像头接口
    input                 cam_pclk        ,  //cmos 数据像素时钟
    input                 cam_vsync       ,  //cmos 场同步信号
    input                 cam_href        ,  //cmos 行同步信号
    input        [7:0]    cam_data        ,  //cmos 数据                             
    //用户接口
    output                cmos_frame_vsync,  //帧有效信号
    output                cmos_frame_href ,  //行有效信号
    output                cmos_frame_valid,  //数据有效使能信号
    output       [7:0]    cmos_frame_data    //有效数据
    );

//寄存器全部配置完成后，先等待10帧数据
//待寄存器配置生效后再开始采集图像
parameter  WAIT_FRAME = 4'd10  ;             //寄存器数据稳定等待的帧个数            

//reg define
reg             cam_vsync_d0   ;
reg             cam_vsync_d1   ;
reg             cam_href_d0    ;
reg             cam_href_d1    ;
reg    [3:0]    cmos_ps_cnt    ;             //等待帧数稳定计数器
reg             frame_val_flag ;             //帧有效的标志
          
wire    [7:0]    cmos_data_t    ;         
wire             byte_flag_d0   ;

//wire define
wire            pos_vsync      ;

//*****************************************************
//**                    main code
//*****************************************************

//采输入场同步信号的上升沿
assign pos_vsync = (~cam_vsync_d1) & cam_vsync_d0;  

assign byte_flag_d0 = cam_pclk & cam_vsync & cam_href;

assign cmos_data_t[0] = cam_data[0] & cam_vsync & cam_href;
assign cmos_data_t[1] = cam_data[1] & cam_vsync & cam_href;
assign cmos_data_t[2] = cam_data[2] & cam_vsync & cam_href;
assign cmos_data_t[3] = cam_data[3] & cam_vsync & cam_href;
assign cmos_data_t[4] = cam_data[4] & cam_vsync & cam_href;
assign cmos_data_t[5] = cam_data[5] & cam_vsync & cam_href;
assign cmos_data_t[6] = cam_data[6] & cam_vsync & cam_href;
assign cmos_data_t[7] = cam_data[7] & cam_vsync & cam_href;

//输出帧有效信号
assign  cmos_frame_vsync = frame_val_flag  ?  cam_vsync_d1  :  1'b0; 
//输出行有效信号
assign  cmos_frame_href  = frame_val_flag  ?  cam_href_d1   :  1'b0; 
//输出数据使能有效信号
assign  cmos_frame_valid = frame_val_flag  ?  byte_flag_d0  :  1'b0; 
//输出数据
assign  cmos_frame_data  = frame_val_flag  ?  cmos_data_t   :  1'b0; 

//采输入场同步信号的上升沿
always @(posedge cam_pclk or negedge rst_n) begin
    if(!rst_n) begin
        cam_vsync_d0 <= 1'b0;
        cam_vsync_d1 <= 1'b0;
        cam_href_d0 <= 1'b0;
        cam_href_d1 <= 1'b0;
    end
    else begin
        cam_vsync_d0 <= cam_vsync;
        cam_vsync_d1 <= cam_vsync_d0;
        cam_href_d0 <= cam_href;
        cam_href_d1 <= cam_href_d0;
    end
end

//对帧数进行计数
always @(posedge cam_pclk or negedge rst_n) begin
    if(!rst_n)
        cmos_ps_cnt <= 4'd0;
    else if(pos_vsync && (cmos_ps_cnt < WAIT_FRAME))
        cmos_ps_cnt <= cmos_ps_cnt + 4'd1;
end

//帧有效标志
always @(posedge cam_pclk or negedge rst_n) begin
    if(!rst_n)
        frame_val_flag <= 1'b0;
    else if((cmos_ps_cnt == WAIT_FRAME) && pos_vsync)
        frame_val_flag <= 1'b1;
    else;    
end

endmodule