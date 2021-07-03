module i2c_ov2640_cfg
  #(
    parameter CMOS_H_PIXEL = 24'd1600,//CMOS水平方向像素个数
    parameter CMOS_V_PIXEL = 24'd1200 //CMOS垂直方向像素个数
    )
   (
    input                clk      ,   //时钟信号
    input                rst_n    ,   //复位信号，低电平有效
    
    input                i2c_done ,   //I2C寄存器配置完成信号
    output  reg          i2c_exec ,   //I2C触发执行信号   
    output  reg  [23:0]  i2c_data ,   //I2C要配置的地址与数据(高16位地址,低8位数据)
    output  reg          init_done    //初始化完成信号
    );

//parameter define
localparam  REG_NUM = 8'd201  ;       //总共需要配置的寄存器个数
localparam  ZMOW = CMOS_H_PIXEL >> 2;
localparam  ZMOH = CMOS_V_PIXEL >> 2;
localparam  ZMHH = ((CMOS_H_PIXEL >> 10)&8'h3)|((CMOS_V_PIXEL >> 8)&8'h4);

//reg define
reg   [14:0]   start_init_cnt;        //等待延时计数器
reg    [7:0]   init_reg_cnt  ;        //寄存器配置个数计数器

//*****************************************************
//**                    main code
//*****************************************************

//cam_scl配置成250khz,输入的clk为1Mhz,周期为1us,20000*1us = 20ms
//OV5640上电到开始配置IIC至少等待20ms
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        start_init_cnt <= 15'd0;
    else if(start_init_cnt < 15'd20000)
        start_init_cnt <= start_init_cnt + 1'b1;                    
end

//寄存器配置个数计数    
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        init_reg_cnt <= 8'd0;
    else if(i2c_exec)   
        init_reg_cnt <= init_reg_cnt + 8'b1;
end

//i2c触发执行信号   
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        i2c_exec <= 1'b0;
    else if(start_init_cnt == 15'd19999)
        i2c_exec <= 1'b1;
    else if(i2c_done && (init_reg_cnt < REG_NUM))
        i2c_exec <= 1'b1;
    else
        i2c_exec <= 1'b0;
end 

//初始化完成信号
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        init_done <= 1'b0;
    else if((init_reg_cnt == REG_NUM) && i2c_done)  
        init_done <= 1'b1;  
end

//配置寄存器地址与数据
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        i2c_data <= 24'd0;
    else begin
        case(init_reg_cnt)
            //先对寄存器进行软件复位，使寄存器恢复初始值
            8'd0	:i2c_data[15:0] <= {8'hff,8'h01};
            8'd1	:i2c_data[15:0] <= {8'h12,8'h80};
            8'd2	:i2c_data[15:0] <= {8'hff,8'h00};
            8'd3	:i2c_data[15:0] <= {8'h2c,8'hff};
            8'd4	:i2c_data[15:0] <= {8'h2e,8'hdf};
            8'd5	:i2c_data[15:0] <= {8'hff,8'h01};
            8'd6	:i2c_data[15:0] <= {8'h3c,8'h32};
            8'd7	:i2c_data[15:0] <= {8'h11,8'h00};
//            8'd7	:i2c_data[15:0] <= {8'h11,8'h04};           //div4
            8'd8	:i2c_data[15:0] <= {8'h09,8'h02};
            8'd9	:i2c_data[15:0] <= {8'h04,8'h20};
            8'd10	:i2c_data[15:0] <= {8'h13,8'he5};
            8'd11	:i2c_data[15:0] <= {8'h14,8'h48};
            8'd12	:i2c_data[15:0] <= {8'h2c,8'h0c};
            8'd13	:i2c_data[15:0] <= {8'h33,8'h78};
            8'd14	:i2c_data[15:0] <= {8'h3a,8'h33};
            8'd15	:i2c_data[15:0] <= {8'h3b,8'hfB};
            8'd16	:i2c_data[15:0] <= {8'h3e,8'h00};
            8'd17	:i2c_data[15:0] <= {8'h43,8'h11};
            8'd18	:i2c_data[15:0] <= {8'h16,8'h10};
            8'd19	:i2c_data[15:0] <= {8'h39,8'h92};
            8'd20	:i2c_data[15:0] <= {8'h35,8'hda};
            8'd21	:i2c_data[15:0] <= {8'h22,8'h1a};
            8'd22	:i2c_data[15:0] <= {8'h37,8'hc3};
            8'd23	:i2c_data[15:0] <= {8'h23,8'h00};
            8'd24	:i2c_data[15:0] <= {8'h34,8'hc0};
            8'd25	:i2c_data[15:0] <= {8'h36,8'h1a};
            8'd26	:i2c_data[15:0] <= {8'h06,8'h88};
            8'd27	:i2c_data[15:0] <= {8'h07,8'hc0};
            8'd28	:i2c_data[15:0] <= {8'h0d,8'h87};
            8'd29	:i2c_data[15:0] <= {8'h0e,8'h41};
            8'd30	:i2c_data[15:0] <= {8'h4c,8'h00};
            8'd31	:i2c_data[15:0] <= {8'h48,8'h00};
            8'd32	:i2c_data[15:0] <= {8'h5B,8'h00};
            8'd33	:i2c_data[15:0] <= {8'h42,8'h03};
            8'd34	:i2c_data[15:0] <= {8'h4a,8'h81};
            8'd35	:i2c_data[15:0] <= {8'h21,8'h99};
            8'd36	:i2c_data[15:0] <= {8'h24,8'h40};
            8'd37	:i2c_data[15:0] <= {8'h25,8'h38};
            8'd38	:i2c_data[15:0] <= {8'h26,8'h82};
            8'd39	:i2c_data[15:0] <= {8'h5c,8'h00};
            8'd40	:i2c_data[15:0] <= {8'h63,8'h00};
            8'd41	:i2c_data[15:0] <= {8'h46,8'h00};
            8'd42	:i2c_data[15:0] <= {8'h0c,8'h3c};
            8'd43	:i2c_data[15:0] <= {8'h61,8'h70};
            8'd44	:i2c_data[15:0] <= {8'h62,8'h80};
            8'd45	:i2c_data[15:0] <= {8'h7c,8'h05};
            8'd46	:i2c_data[15:0] <= {8'h20,8'h80};
            8'd47	:i2c_data[15:0] <= {8'h28,8'h30};
            8'd48	:i2c_data[15:0] <= {8'h6c,8'h00};
            8'd49	:i2c_data[15:0] <= {8'h6d,8'h80};
            8'd50	:i2c_data[15:0] <= {8'h6e,8'h00};
            8'd51	:i2c_data[15:0] <= {8'h70,8'h02};
            8'd52	:i2c_data[15:0] <= {8'h71,8'h94};
            8'd53	:i2c_data[15:0] <= {8'h73,8'hc1};
            8'd54	:i2c_data[15:0] <= {8'h3d,8'h34};
            8'd55	:i2c_data[15:0] <= {8'h5a,8'h57};
            8'd56	:i2c_data[15:0] <= {8'h12,8'h00};
            8'd57	:i2c_data[15:0] <= {8'h17,8'h11};
            8'd58	:i2c_data[15:0] <= {8'h18,8'h75};
            8'd59	:i2c_data[15:0] <= {8'h19,8'h01};
            8'd60	:i2c_data[15:0] <= {8'h1a,8'h97};
            8'd61	:i2c_data[15:0] <= {8'h32,8'h36};           //no effect on pclk
            8'd62	:i2c_data[15:0] <= {8'h03,8'h0f};
            8'd63	:i2c_data[15:0] <= {8'h37,8'h40};
            8'd64	:i2c_data[15:0] <= {8'h4f,8'hca};
            8'd65	:i2c_data[15:0] <= {8'h50,8'ha8};
            8'd66	:i2c_data[15:0] <= {8'h5a,8'h23};
            8'd67	:i2c_data[15:0] <= {8'h6d,8'h00};
            8'd68	:i2c_data[15:0] <= {8'h6d,8'h38};
            8'd69	:i2c_data[15:0] <= {8'hff,8'h00};
            8'd70	:i2c_data[15:0] <= {8'he5,8'h7f};
            8'd71	:i2c_data[15:0] <= {8'hf9,8'hc0};
            8'd72	:i2c_data[15:0] <= {8'h41,8'h24};
            8'd73	:i2c_data[15:0] <= {8'he0,8'h14};
            8'd74	:i2c_data[15:0] <= {8'h76,8'hff};
            8'd75	:i2c_data[15:0] <= {8'h33,8'ha0};
            8'd76	:i2c_data[15:0] <= {8'h42,8'h20};
            8'd77	:i2c_data[15:0] <= {8'h43,8'h18};
            8'd78	:i2c_data[15:0] <= {8'h4c,8'h00};
            8'd79	:i2c_data[15:0] <= {8'h87,8'hd5};
            8'd80	:i2c_data[15:0] <= {8'h88,8'h3f};
            8'd81	:i2c_data[15:0] <= {8'hd7,8'h03};
            8'd82	:i2c_data[15:0] <= {8'hd9,8'h10};
            8'd83	:i2c_data[15:0] <= {8'hd3,8'h82};
            8'd84	:i2c_data[15:0] <= {8'hc8,8'h08};
            8'd85	:i2c_data[15:0] <= {8'hc9,8'h80};
            8'd86	:i2c_data[15:0] <= {8'h7c,8'h00};
            8'd87	:i2c_data[15:0] <= {8'h7d,8'h00};
            8'd88	:i2c_data[15:0] <= {8'h7c,8'h03};
            8'd89	:i2c_data[15:0] <= {8'h7d,8'h48};
            8'd90	:i2c_data[15:0] <= {8'h7d,8'h48};
            8'd91	:i2c_data[15:0] <= {8'h7c,8'h08};
            8'd92	:i2c_data[15:0] <= {8'h7d,8'h20};
            8'd93	:i2c_data[15:0] <= {8'h7d,8'h10};
            8'd94	:i2c_data[15:0] <= {8'h7d,8'h0e};
            8'd95	:i2c_data[15:0] <= {8'h90,8'h00};
            8'd96	:i2c_data[15:0] <= {8'h91,8'h0e};
            8'd97	:i2c_data[15:0] <= {8'h91,8'h1a};
            8'd98	:i2c_data[15:0] <= {8'h91,8'h31};
            8'd99	:i2c_data[15:0] <= {8'h91,8'h5a};
            8'd100	:i2c_data[15:0] <= {8'h91,8'h69};
            8'd101	:i2c_data[15:0] <= {8'h91,8'h75};
            8'd102	:i2c_data[15:0] <= {8'h91,8'h7e};
            8'd103	:i2c_data[15:0] <= {8'h91,8'h88};
            8'd104	:i2c_data[15:0] <= {8'h91,8'h8f};
            8'd105	:i2c_data[15:0] <= {8'h91,8'h96};
            8'd106	:i2c_data[15:0] <= {8'h91,8'ha3};
            8'd107	:i2c_data[15:0] <= {8'h91,8'haf};
            8'd108	:i2c_data[15:0] <= {8'h91,8'hc4};
            8'd109	:i2c_data[15:0] <= {8'h91,8'hd7};
            8'd110	:i2c_data[15:0] <= {8'h91,8'he8};
            8'd111	:i2c_data[15:0] <= {8'h91,8'h20};
            8'd112	:i2c_data[15:0] <= {8'h92,8'h00};
            8'd113	:i2c_data[15:0] <= {8'h93,8'h06};
            8'd114	:i2c_data[15:0] <= {8'h93,8'he3};
            8'd115	:i2c_data[15:0] <= {8'h93,8'h05};
            8'd116	:i2c_data[15:0] <= {8'h93,8'h05};
            8'd117	:i2c_data[15:0] <= {8'h93,8'h00};
            8'd118	:i2c_data[15:0] <= {8'h93,8'h04};
            8'd119	:i2c_data[15:0] <= {8'h93,8'h00};
            8'd120	:i2c_data[15:0] <= {8'h93,8'h00};
            8'd121	:i2c_data[15:0] <= {8'h93,8'h00};
            8'd122	:i2c_data[15:0] <= {8'h93,8'h00};
            8'd123	:i2c_data[15:0] <= {8'h93,8'h00};
            8'd124	:i2c_data[15:0] <= {8'h93,8'h00};
            8'd125	:i2c_data[15:0] <= {8'h93,8'h00};
            8'd126	:i2c_data[15:0] <= {8'h96,8'h00};
            8'd127	:i2c_data[15:0] <= {8'h97,8'h08};
            8'd128	:i2c_data[15:0] <= {8'h97,8'h19};
            8'd129	:i2c_data[15:0] <= {8'h97,8'h02};
            8'd130	:i2c_data[15:0] <= {8'h97,8'h0c};
            8'd131	:i2c_data[15:0] <= {8'h97,8'h24};
            8'd132	:i2c_data[15:0] <= {8'h97,8'h30};
            8'd133	:i2c_data[15:0] <= {8'h97,8'h28};
            8'd134	:i2c_data[15:0] <= {8'h97,8'h26};
            8'd135	:i2c_data[15:0] <= {8'h97,8'h02};
            8'd136	:i2c_data[15:0] <= {8'h97,8'h98};
            8'd137	:i2c_data[15:0] <= {8'h97,8'h80};
            8'd138	:i2c_data[15:0] <= {8'h97,8'h00};
            8'd139	:i2c_data[15:0] <= {8'h97,8'h00};
            8'd140	:i2c_data[15:0] <= {8'hc3,8'hef};
            8'd141	:i2c_data[15:0] <= {8'ha4,8'h00};
            8'd142	:i2c_data[15:0] <= {8'ha8,8'h00};
            8'd143	:i2c_data[15:0] <= {8'hc5,8'h11};
            8'd144	:i2c_data[15:0] <= {8'hc6,8'h51};
            8'd145	:i2c_data[15:0] <= {8'hbf,8'h80};
            8'd146	:i2c_data[15:0] <= {8'hc7,8'h10};
            8'd147	:i2c_data[15:0] <= {8'hb6,8'h66};
            8'd148	:i2c_data[15:0] <= {8'hb8,8'hA5};
            8'd149	:i2c_data[15:0] <= {8'hb7,8'h64};
            8'd150	:i2c_data[15:0] <= {8'hb9,8'h7C};
            8'd151	:i2c_data[15:0] <= {8'hb3,8'haf};
            8'd152	:i2c_data[15:0] <= {8'hb4,8'h97};
            8'd153	:i2c_data[15:0] <= {8'hb5,8'hFF};
            8'd154	:i2c_data[15:0] <= {8'hb0,8'hC5};
            8'd155	:i2c_data[15:0] <= {8'hb1,8'h94};
            8'd156	:i2c_data[15:0] <= {8'hb2,8'h0f};
            8'd157	:i2c_data[15:0] <= {8'hc4,8'h5c};
            8'd158	:i2c_data[15:0] <= {8'hc0,8'hc8};
            8'd159	:i2c_data[15:0] <= {8'hc1,8'h96};
            8'd160	:i2c_data[15:0] <= {8'h8c,8'h00};
            8'd161	:i2c_data[15:0] <= {8'h86,8'h3d};
            8'd162	:i2c_data[15:0] <= {8'h50,8'h00};
            8'd163	:i2c_data[15:0] <= {8'h51,8'h90};
            8'd164	:i2c_data[15:0] <= {8'h52,8'h2c};
            8'd165	:i2c_data[15:0] <= {8'h53,8'h00};
            8'd166	:i2c_data[15:0] <= {8'h54,8'h00};
            8'd167	:i2c_data[15:0] <= {8'h55,8'h88};
            8'd168	:i2c_data[15:0] <= {8'h5a,8'h90};
            8'd169	:i2c_data[15:0] <= {8'h5b,8'h2C};
            8'd170	:i2c_data[15:0] <= {8'h5c,8'h05};
            8'd171	:i2c_data[15:0] <= {8'hd3,8'h02};
            8'd172	:i2c_data[15:0] <= {8'hc3,8'hed};
            8'd173	:i2c_data[15:0] <= {8'h7f,8'h00};
            8'd174	:i2c_data[15:0] <= {8'hda,8'h09};
            8'd175	:i2c_data[15:0] <= {8'he5,8'h1f};
            8'd176	:i2c_data[15:0] <= {8'he1,8'h67};
            8'd177	:i2c_data[15:0] <= {8'he0,8'h00};
            8'd178	:i2c_data[15:0] <= {8'hdd,8'h7f};
            8'd179	:i2c_data[15:0] <= {8'h05,8'h00};
            8'd180	:i2c_data[15:0] <= {8'hFF,8'h00};
            8'd181	:i2c_data[15:0] <= {8'hDA,8'h10};
            8'd182	:i2c_data[15:0] <= {8'hD7,8'h03};
            8'd183	:i2c_data[15:0] <= {8'hDF,8'h00};
            8'd184	:i2c_data[15:0] <= {8'h33,8'h80};
            8'd185	:i2c_data[15:0] <= {8'h3C,8'h40};
            8'd186	:i2c_data[15:0] <= {8'he1,8'h77};
            8'd187	:i2c_data[15:0] <= {8'h00,8'h00};
            8'd188	:i2c_data[15:0] <= {8'hff,8'h01};
            8'd189	:i2c_data[15:0] <= {8'he0,8'h14};
            8'd190	:i2c_data[15:0] <= {8'he1,8'h77};
            8'd191	:i2c_data[15:0] <= {8'he5,8'h1f};
            8'd192	:i2c_data[15:0] <= {8'hd7,8'h03};
            8'd193	:i2c_data[15:0] <= {8'hda,8'h10};
            8'd194	:i2c_data[15:0] <= {8'he0,8'h00};
            8'd195	:i2c_data[15:0] <= {8'hff,8'h00};
            8'd196	:i2c_data[15:0] <= {8'he0,8'h04};
            8'd197	:i2c_data[15:0] <= {8'h5a,ZMOW[7:0]};
            8'd198	:i2c_data[15:0] <= {8'h5b,ZMOH[7:0]};
            8'd199	:i2c_data[15:0] <= {8'h5c,ZMHH[7:0]};
            8'd200	:i2c_data[15:0] <= {8'he0,8'h00};
            //只读存储器,防止在case中没有列举的情况，之前的寄存器被重复改写
            default : i2c_data <= {8'h1c,8'h00}; //器件ID高8位
        endcase
    end
end

endmodule