# AXI_DMA_CONTROLLER
## Description
The design can split the command into multiple bursts.Only the first burst will be processed, and none of the bursts will cross the 4k boundary.
The read_master model support outstanding.There are two versions of slave that support outstanding and not outstanding.Testbench sends the same command to the DMA read/write channel and work on the same area.
Some signals are not used,such as CHCHE,LOCK and QOS.
The rtl code is written in style of xilinx.
## Block Diagram  
![屏幕截图 2022-10-15 093724](https://user-images.githubusercontent.com/71507230/195963426-b8ddd280-effa-406f-9c0c-c71f72a0b3ef.png)
## Configuration Parameters
|Name|Description|Default|
|---|---|---|
|AXI_ID_WD||2|
|AXI_DATA_WD||32|
|AXI_ADDR_WD||32|
|AXI_STRB_WD||4|
## Signal and Interface Pins
|Name|Description|
|---|---|
|AXI_ACLK|All signals and are synchronous to this clock.| 
|AXI_ARESETN|Resets the internal state of the peripheral.|
|cmd_valid||
|cmd_ready||
|cmd_addr||
|cmd_id||
|cmd_burst||
|cmd_size||
|cmd_len||
|cmd_abort||  


未完工
   


