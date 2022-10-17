# AXI_DMA_CONTROLLER
## Description
The design can split the command into multiple bursts.Only the first burst will be processed, and none of the bursts will cross the 4k boundary.
The master_read module support outstanding.There are two versions of slave that support outstanding and not outstanding.Testbench sends the same command to the DMA read/write channel and work on the same area.
Some signals are not used,such as CHCHE,LOCK and QOS.
The rtl code is written in style of xilinx.
## Block Diagram  
![DMA](https://user-images.githubusercontent.com/71507230/195978585-41bc8f4e-98f2-4c5d-bc76-31d7b54459ff.png)
![master_read](https://user-images.githubusercontent.com/71507230/196185715-fe8f4253-aa73-49c6-b00f-5a8ba58079b1.png)



## Configuration Parameters
|Name|Description|Default|
|---|---|---|
|AXI_ID_WD|Identification path width in bits.|2|
|AXI_DATA_WD|Data path width in bits.|32|
|AXI_ADDR_WD|Address path width in bits.|32|
|AXI_STRB_WD|Strobe path width in bits.|4|
## Signal and Interface Ports
|Name|Direction|Description|
|---|---|---|
|AXI_ACLK|input|All signals and are synchronous to this clock.| 
|AXI_ARESETN|input|Resets the internal state of the peripheral.|
|cmd_valid|input|Whether the command is valid|
|cmd_ready|output|Whether the slave is ready|
|cmd_addr|input|The memory address to porcess|
|cmd_id|input|The identification of command|
|cmd_burst|input|Type of burst transter|
|cmd_size|input|The number of bytes transmitted per beat|
|cmd_len|input|The number of bytes to process|
|cmd_abort|output|Signal of error|  
## Design Details
![master_write](https://user-images.githubusercontent.com/71507230/196181820-961c13fc-97cc-4ead-8bdc-a40b2c65e747.png)

![outstanding](https://user-images.githubusercontent.com/71507230/196180171-00fe5124-560f-401f-8889-ddf546a94f5d.png)

![屏幕截图 2022-10-15 101423](https://user-images.githubusercontent.com/71507230/195964400-5c02999c-702b-44b1-9bfb-c61c75a74b56.png)




## To be continiued
   


