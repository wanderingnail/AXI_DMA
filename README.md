# AXI_DMA_CONTROLLER
## Description
The rtl code is written in style of xilinx.It can split the command into multiple bursts and only the first burst has to deal with 4k boundary.
## Block Diagram  
![image](https://user-images.githubusercontent.com/71507230/195854675-7dc040a5-a50e-4d52-b9fd-0b9ffeac3024.png)
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
   
读通道的master支持outstanding，slave有支持outstanding和不支持两个版本，如果例化的是不支持的版本，读通道也会像写通道一样读完一个burst再发下一个请求。
tb向DMA的读写通道发同样的命令，同时读写同一块区域。
没有用到AXI协议的CACHE,lOCK,和QOS信号。
