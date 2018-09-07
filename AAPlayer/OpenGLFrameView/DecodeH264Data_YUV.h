//
//  IPCamera
//
//  Created by chenchao on 13-1-1.
//  Copyright (c) 2013年 chenchao. All rights reserved.
//

#ifndef _DECODEH264DATA_YUV_
#define _DECODEH264DATA_YUV_

#pragma pack(push, 1)

typedef struct H264FrameDef
{
    unsigned int    length;
    uint32_t*  dataBuffer;
    
}H264Frame;

typedef struct  H264YUVDef
{
    unsigned int    width;
    unsigned int    height;
    H264Frame       luma;
    H264Frame       chromaB;
    H264Frame       chromaR;
    
}H264YUV_Frame;


#pragma pack(pop)

#endif
