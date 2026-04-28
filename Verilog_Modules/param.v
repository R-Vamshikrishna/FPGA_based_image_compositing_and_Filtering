`timescale 1ns / 1ps

parameter LINE_LEN                = 512;
parameter GRAYSCALE_DLY           = 3;
parameter LINE_BUF_DLY            = LINE_LEN * 2 + 3;
parameter SOBEL_OP_DLY            = 4;
parameter EDGE_DET_DLY            = 1;
parameter GAUSSIAN_DLY            = 3;
parameter SOBEL_DLY               = GRAYSCALE_DLY + LINE_BUF_DLY + SOBEL_OP_DLY + EDGE_DET_DLY;

parameter GRADIENT_EDGE_THRESHOLD = 15'd50;
parameter CARTOON_EDGE_THRESHOLD  = 15'd100;

parameter SEPIA                   = 3'b000;
parameter INVERT                  = 3'b001;
parameter EDGE                    = 3'b010;
parameter CARTOON                 = 3'b011;
parameter GRAYSCALE               = 3'b100;
