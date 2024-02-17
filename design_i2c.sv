


module design_i2c#(parameter DATA_WIDTH=24)
                  (
                   //global clk and asynchronous reset
                    input ACLK,
                    input ARESETn,
                    
                    //trigger signal
                    input I2C_MASTER_TRIGGER,
                    
                    //communication signals for inputs and outputs
                    input logic SDA_i,
                    output logic SDA_o,
                    input logic SCL_i,
                    //output logic SCL_o,
                    
                    //address and data signal
                    input  [DATA_WIDTH-1:0] ADDR_DATA_OUT,
                    input logic VALID_ADDR_DATA_OUT,
                    
                    //valid ack signals for read data and write data
                    input logic  RDATA_VALID_ACK,
                    output logic VALID_ADDR_DATA_OUT_ACK,
                    
                    //valid ack signal
                    output logic VALID_ADDR_DATA_OUT_ACK_VALID,
                    
                    //read signals
                    output logic [7:0]RDATA_OUT,
                    output logic RDATA_VALID,
                    
                    //pending signals
                    output logic PENDING_TRANSACTION_WR,
                    output logic PENDING_TRANSACTION_RD);
                    

//internal signals 

//defining transition states using enum
typedef enum logic [3:0] {IDLE,START,SEND_ADDR,READ_WRITE,ADDR_ACK_NACK,SEND_DATA,PENDING_TRANSACTION,DATA_ACK_NACK,STOP} states;

//Device Id's for I2C
reg I2C_MASTER_1 = 24'h000001;
reg I2C_MASTER_2 = 24'h000010;
reg I2C_MASTER_3 = 24'h000011;
reg I2C_MASTER_4 = 24'h000100;
reg I2C_MASTER_5 = 24'h000101;
reg I2C_MASTER_6 = 24'h000110;
reg I2C_MASTER_7 = 24'h000111;
reg I2C_MASTER_8 = 24'h001000;
reg I2C_MASTER_9 = 24'h001001;

//Synchronous De-assertions registers
reg reset_out;
reg SYN_ARESETn;

//states
reg [3:0]present_state,next_state;

//counter signal
logic [2:0] bit_addr_counter;
logic [3:0] bit_addr_data_counter;
logic  [15:0] memory_address_data;
logic  [7:0] device_address;
//logic [7:0] given_address;
logic start;
logic stop;
//reg [7:0] temp_addr_shift;
//reg serial_out;
//reg load;
//reg  read_write;

//reset synchronizer
always_ff@(posedge ACLK,negedge ARESETn)
   begin
     if(~ARESETn)
        {reset_out,SYN_ARESETn} <= 2'b0;
     else 
        {SYN_ARESETn,reset_out} <= {reset_out,1'b1};
   end    
   
////registers of SDA and SCL
//reg temp_SDA_i;
//reg temp_SCL_i;
//reg temp_SDA_o;
//reg temp_SCL_o;

////registering SDA and SCL
//always_ff@(posedge ACLK,negedge SYN_ARESETn)
//  begin
//    if(~SYN_ARESETn)
//      begin
//        temp_SDA_i <= 0;
//        temp_SCL_i <= 0;
//        temp_SDA_o <= 0;
//        temp_SCL_o <= 0;
//      end
//    else
//      begin
//        temp_SDA_i <= SDA_i;
//        temp_SCL_i <= SCL_i;
//        temp_SDA_o <= SDA_i;
//        temp_SCL_o <= SCL_i;
//      end
//  end
 
////CDC for input signals  
////CDC I2C_MASTER_TRIGGER//
//reg q1_I2C_MASTER_TRIGGER;
//reg q2_I2C_MASTER_TRIGGER;
//reg q3_I2C_MASTER_TRIGGER;
//reg L2P_I2C_MASTER_TRIGGER;

//always_ff@(posedge ACLK,negedge SYN_ARESETn)
// begin
//   if(~SYN_ARESETn)
//     begin
//       {q1_I2C_MASTER_TRIGGER,q2_I2C_MASTER_TRIGGER} <= 0;
//     end
//   else
//     begin
//       {q1_I2C_MASTER_TRIGGER,q2_I2C_MASTER_TRIGGER} <= {I2C_MASTER_TRIGGER,q1_I2C_MASTER_TRIGGER};
//     end 
// end
  
//always_ff@(posedge ACLK,negedge SYN_ARESETn)
//   begin
//     if(~SYN_ARESETn)
//       begin
//         q3_I2C_MASTER_TRIGGER <= 0;
//       end
//     else
//       begin
//         q3_I2C_MASTER_TRIGGER <= q2_I2C_MASTER_TRIGGER;
//       end
//  end
////level to pulse conversion     
//assign L2P_I2C_MASTER_TRIGGER = q3_I2C_MASTER_TRIGGER ^ q2_I2C_MASTER_TRIGGER;

  
   
////CDC VALID_ADDR_DATA_OUT//
//reg q1_VALID_ADDR_DATA_OUT;
//reg q2_VALID_ADDR_DATA_OUT;
//reg q3_VALID_ADDR_DATA_OUT;
//reg L2P_VALID_ADDR_DATA_OUT;

//always_ff@(posedge ACLK,negedge SYN_ARESETn)
// begin
//   if(~SYN_ARESETn)
//     begin
//       {q1_VALID_ADDR_DATA_OUT,q2_VALID_ADDR_DATA_OUT} <= 0;
//     end
//   else
//     begin
//       {q1_VALID_ADDR_DATA_OUT,q2_VALID_ADDR_DATA_OUT} <= {VALID_ADDR_DATA_OUT,q1_VALID_ADDR_DATA_OUT};
//     end 
// end
  
//always_ff@(posedge ACLK,negedge SYN_ARESETn)
//   begin
//     if(~SYN_ARESETn)
//       begin
//         q3_VALID_ADDR_DATA_OUT  <= 0;
//       end
//     else
//       begin
//         q3_VALID_ADDR_DATA_OUT <= q2_VALID_ADDR_DATA_OUT;
//       end
//  end
////level to pulse conversion     
//assign L2P_VALID_ADDR_DATA_OUT = q3_VALID_ADDR_DATA_OUT ^ q2_VALID_ADDR_DATA_OUT;


////CDC RDATA_VALID_ACK
//logic q1_RDATA_VALID_ACK;
//logic q2_RDATA_VALID_ACK;
//logic q3_RDATA_VALID_ACK;
//logic L2P_RDATA_VALID_ACK;

//always_ff@(posedge ACLK,negedge SYN_ARESETn)
// begin
//   if(~SYN_ARESETn)
//     begin
//       {q1_RDATA_VALID_ACK,q2_RDATA_VALID_ACK} <= 0;
//     end
//   else
//     begin
//       {q1_RDATA_VALID_ACK,q2_RDATA_VALID_ACK} <= {RDATA_VALID_ACK,q1_RDATA_VALID_ACK};
//     end 
// end
  
//always_ff@(posedge ACLK,negedge SYN_ARESETn)
//   begin
//     if(~SYN_ARESETn)
//       begin
//         q3_RDATA_VALID_ACK  <= 0;
//       end
//     else
//       begin
//         q3_RDATA_VALID_ACK <= q2_RDATA_VALID_ACK;
//       end
//  end
////level to pulse conversion     
//assign L2P_RDATA_VALID_ACK = q3_RDATA_VALID_ACK ^ q2_RDATA_VALID_ACK;
 
 
////CDC for output signals
 
 
 
//always_ff@(posedge SCL_i,negedge SYN_ARESETn)
//  begin
//    if(~SYN_ARESETn)
//      temp_addr_shift <= 'b0;
//    else
//      if(!load)
//        temp_addr_shift <= ADDR_DATA_OUT[23:17];
//      else
//        temp_addr_shift <= {temp_addr_shift[6:0],1'b0};
//   end
   
//assign serial = temp_addr_shift[7];    
//RESET condition                                                                                                                                                                                                                                                                                                                                                                      
always_ff@(posedge SCL_i,negedge SYN_ARESETn)
   begin
     if(!SYN_ARESETn)
      begin
       present_state <= IDLE;
      end
     else
      begin 
       present_state <= next_state;
      end
   end 
   
//assigning the values
//logic device_address;
assign device_address = ADDR_DATA_OUT[23:17];
//assign read_write = ADDR_DATA_OUT[16];
assign memory_address_data = ADDR_DATA_OUT[15:0];
//assign data = ADDR_DATA_OUT[7:0];

//combinational logic for state transitions 
always_comb
   begin
        case(present_state)
            IDLE:begin:idle_state
                    if(!SDA_i && I2C_MASTER_TRIGGER)
                     begin
                        next_state = START;
                     end
                    else
                     begin
                        next_state = IDLE;
                     end
                 end:idle_state
        //checking for the start condition
            START:begin:start_state
                     if(VALID_ADDR_DATA_OUT)
                      next_state  = SEND_ADDR;
                    else
                      next_state  = START;
                  end:start_state
          //sending address serially to the slave
            SEND_ADDR:begin:send_addr_state
                    if(ADDR_DATA_OUT)
                      if(device_address)
                         next_state = READ_WRITE;
                      else 
                         next_state = START;
                    end:send_addr_state
           //writing to the slave
            READ_WRITE:begin:read_write_state
                         if(!ADDR_DATA_OUT[16])
                            next_state = ADDR_ACK_NACK;
//                         else if(!read_write)
//                            next_state = ADDR_ACK_NACK;
//                         else
//                            next_state = IDLE;
                       end:read_write_state
           //receiving conformation from slave whether the address is valid or not
            ADDR_ACK_NACK:begin:addr_ack_nack_state
                            if(ADDR_DATA_OUT[15])
                              next_state = SEND_DATA;
                            else
                              next_state = IDLE;
                          end:addr_ack_nack_state
            //sending data to slave serially
            SEND_DATA:begin:send_data_state
                        if(!ADDR_DATA_OUT[16] && ADDR_DATA_OUT[15:0]== memory_address_data)
                           begin
                             //ADDR_DATA_OUT = 
                             next_state = PENDING_TRANSACTION;
                           end
//                        else if(!read_write)
//                               if(
//                             next_state = ;
//                       else
//                             next_state = IDLE;
                     end:send_data_state
          
          
           //pending transactions
            PENDING_TRANSACTION:begin
                                  if(!ADDR_DATA_OUT[16] && bit_addr_data_counter == 4'b1111)
                                    next_state = DATA_ACK_NACK;
                                  else
                                    next_state = PENDING_TRANSACTION;
                                end
          
          //receiving conformation from slave whether the data is reached or not
           DATA_ACK_NACK:begin:data_ack_nack_state
                         if(!ADDR_DATA_OUT[16] && SDA_i)
                           begin
                             next_state = STOP;
                           end
//                         else if(!read_write)
//                           begin
//                             next_state = IDLE;
//                           end
                        end:data_ack_nack_state
             
          //stop condition
            STOP : begin:stop_state
                      if(SDA_i) 
                         next_state = IDLE;
                      else
                         next_state = DATA_ACK_NACK;
                   end
           
           //default same as idle state
           default :begin:default_state
                    if(!SDA_i && I2C_MASTER_TRIGGER)
                     begin
                        next_state = START;
                     end
                    else
                     begin
                        next_state = IDLE;
                     end
                     end:default_state 
    endcase
  end
  
  
//output logic
always_comb
 begin
 
  case(present_state)
    
    IDLE:begin
           {VALID_ADDR_DATA_OUT_ACK,VALID_ADDR_DATA_OUT_ACK_VALID,RDATA_OUT,RDATA_VALID,PENDING_TRANSACTION_WR,PENDING_TRANSACTION_RD,SDA_o} ='b0;
         end
    
    START:begin
            if(VALID_ADDR_DATA_OUT)
           SDA_o = start;
          end
    
    SEND_ADDR:begin
               
               if(bit_addr_counter < 7)
                 begin 
                   SDA_o = device_address[7-bit_addr_counter];
                   bit_addr_counter = bit_addr_counter + 1;
                end
               else
                   SDA_o = 0;
             end
  
   READ_WRITE:begin
                if(!ADDR_DATA_OUT[16])
                 begin
                   SDA_o = 0;
                   //{address,data} = ADDR_DATA_OUT[14:0];
                 end
                   
//                else 
//                 begin
//                   SDA_o = address;
//                   //{address} = ADDR_DATA_OUT[14:8];
//                 end
             end
   ADDR_ACK_NACK:begin
                  if(!SDA_i && bit_addr_counter == 3'b111)
                     begin 
                       VALID_ADDR_DATA_OUT_ACK = 1;
                       //VALID_ADDR_DATA_OUT_ACK_VALID = 1;
                       SDA_o = 1;
                     end
                  else
                     begin
                       VALID_ADDR_DATA_OUT_ACK = 0;
                       //VALID_ADDR_DATA_OUT_ACK_VALID = 0;
                       SDA_o = 0;
                     end
                end
 
  SEND_DATA:begin
             if(!ADDR_DATA_OUT[16] && bit_addr_data_counter < 15)
              begin
                SDA_o = memory_address_data[15-bit_addr_data_counter];
                bit_addr_data_counter = bit_addr_data_counter+1;
             end
//             else 
//              begin
//                data[7-bit_counter] = SDA_i;
//                RDATA_OUT = data;
//                RDATA_VALID = 1;
//             end
           end 

 PENDING_TRANSACTION:begin
                       if(bit_addr_data_counter == 4'b1111)
                         PENDING_TRANSACTION_WR = 0;
                       else
                         PENDING_TRANSACTION_WR = 1;
                     end
  
  DATA_ACK_NACK : begin
                    if(!ADDR_DATA_OUT[16] && ADDR_DATA_OUT[0])
                     begin
                      
                      VALID_ADDR_DATA_OUT_ACK_VALID = 1;
                     end
//                    else
//                     begin
//                      SDA_o = 1;
//                     end
                end 

          STOP : begin
                   if(SDA_i && !VALID_ADDR_DATA_OUT)
                     SDA_o = stop;
                   else
                     SDA_o = 0;
                 end

          default : begin
                     {VALID_ADDR_DATA_OUT_ACK,VALID_ADDR_DATA_OUT_ACK_VALID,RDATA_OUT,RDATA_VALID,PENDING_TRANSACTION_WR,PENDING_TRANSACTION_RD,SDA_o} ='b0;
                    end
endcase
end
//assign given_address = (24'h000001 | 24'h000010 | 24'h000011 | 24'h000100 | 24'h000101 | 24'h000110 | 24'h000111 | 24'h001000 | 24'h001001);
//assign temp_addr_shift = ADDR_DATA_OUT[23:17];
assign start = 1;
assign stop = 1;
endmodule:design_i2c
