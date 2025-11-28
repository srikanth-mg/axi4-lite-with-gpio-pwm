module pwm
(
input logic clk,
input logic rst_n,
input logic [31:0] duty_cycle,
input logic [31:0] period,
output logic pwm_out
);

logic [31:0] counter; 

always_ff@(posedge clk)begin
if(!rst_n)begin
counter <= 0;
end else begin
if(counter >= period)
counter <= 0;
else 
counter <= counter + 1;
end
end

assign pwm_out = (counter < duty_cycle);

endmodule

