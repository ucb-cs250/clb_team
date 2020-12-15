module mux_kareem #(
    parameter WIDTH=4, ADDR_W=$clog2(WIDTH)
) (input [WIDTH-1:0] data, output out, input [ADDR_W-1:0] addr);

    mux4i impl(.X(out), .S1(addr[0]), .S2(addr[1]), .A1(data[0]), .A2(data[1]), .A3(data[2]), .A4(data[3]));

endmodule
