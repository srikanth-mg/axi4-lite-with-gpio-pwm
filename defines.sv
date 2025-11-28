`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2025 06:09:15 PM
// Design Name: 
// Module Name: defines
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`ifndef DEFINES_SVH
`define DEFINES_SVH

`define GPIO_OUT_ADDR 4'h0
`define GPIO_IN_ADDR 4'h4
`define PWM_CTRL_ADDR 4'h8
`define PWM_PERIOD_ADDR 4'hC

`define GPIO_OUT_RST 32'h0000_0000
`define PWM_CTRL_RST 32'h0000_0000
`define PWM_PERIOD_RST 32'd1000

`define GPIO_WIDTH     8

`endif