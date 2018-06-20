//
//  Schedule.m
//  ExamDemo
//
//  Created by George She on 2018/6/8.
//  Copyright © 2018年 CMRead. All rights reserved.
//

#import "Schedule.h"
#import "NodeInfo.h"
#import "TaskInfo.h"

#define kE000 0  //方法未实现
#define kE001 1  //初始化成功
#define kE002 2  //调度阈值非法
#define kE003 3  //服务节点注册成功
#define kE004 4  //服务节点编号非法
#define kE005 5  //服务节点已注册
#define kE006 6  //服务节点注销成功
#define kE007 7  //服务节点不存在
#define kE008 8  //任务添加成功
#define kE009 9  //任务编号非法
#define kE010 10 //任务已添加
#define kE011 11 //任务删除成功
#define kE012 12 //任务不存在
#define kE013 13 //任务调度成功
#define kE014 14 //无合适迁移方案
#define kE015 15 //查询任务状态成功
#define kE016 16 //参数列表非法

@interface Schedule ()
@property (nonatomic, strong) NSMutableArray *runList;//正在运行的任务队列
@property (nonatomic, strong) NSMutableArray *waitList;//挂起的任务队列
@property (nonatomic, strong) NSMutableArray *nodeList;//当前服务节点列表
@end

@implementation Schedule

- (id)init{
    self = [super init];
    if (self) {
        _nodeList = [NSMutableArray array];
        _runList = [NSMutableArray array];
        _waitList = [NSMutableArray array];
    }
    return self;
}
-(int)clean{
    @synchronized(_runList){
      [_runList removeAllObjects];
    }
    @synchronized(_waitList){
        [_waitList removeAllObjects];
    }
    @synchronized(_nodeList){
        [_nodeList removeAllObjects];
    }
    return kE001;
}

-(int)registerNode:(int)nodeId{
    if (nodeId <= 0) {
        return kE004;
    }
    //根据nodeId查询服务节点是否已经注册
    NodeInfo *nodeInfo = [self nodeInfoForKey:nodeId];
    if (nodeInfo.nodeId > 0) {
        return kE005;
    }
    NodeInfo *newNode = [NodeInfo new];
    newNode.nodeId = nodeId;
    @synchronized(_nodeList){
        [_nodeList addObject:newNode];
    }
    return kE003;
}

-(int)unregisterNode:(int)nodeId{
    if (nodeId <= 0) {
        return kE004;
    }
    NodeInfo *nodeInfo = [self nodeInfoForKey:nodeId];
    if (nodeInfo.nodeId == 0) {
        return kE007;
    }
    if (nodeInfo.status == 1 && nodeInfo.tasks.count > 0) {//有任务，将任务加入挂起队列中
        @synchronized(_waitList){
            [_waitList addObjectsFromArray:nodeInfo.tasks];
        }
    }
    @synchronized(_nodeList){
        [_nodeList removeObject:nodeInfo];
    }
    return kE006;
}

-(int)addTask:(int)taskId withConsumption:(int)consumption{
    if (taskId <= 0) {
        return kE009;
    }
    //疑问？这里确认是否有重复的任务编号，一般是唯一的
    TaskInfo *task = [self taskInfoInWaitListWithId:taskId];
    if (task) {
        return kE010;
    }
    TaskInfo *newTask = [TaskInfo new];
    newTask.taskId = taskId;
    newTask.consumption = consumption;
    @synchronized(_waitList){
        [_waitList addObject:newTask];
    }
    return kE008;
}

-(int)deleteTask:(int)taskId{
    if (taskId <= 0) {
        return kE009;
    }
    //在挂起队列中查询，有删除
    TaskInfo *task = [self taskInfoInWaitListWithId:taskId];
    if (task) {
        @synchronized(_waitList){
            [_waitList removeObject:task];
        }
        return kE011;
    }else {
       if (self.nodeList.count > 0) {
           NSMutableArray *temp = [NSMutableArray array];
           for (NodeInfo *node in _nodeList) {
               TaskInfo *task = [node taskInfoWithId:taskId];
               if (task) {
                [temp addObject:node];
               }
           }
           if (temp.count == 0) {
              return kE012;
           }else{
             for (NodeInfo *node in temp) {
                [node removeTask:taskId];
             }
            return kE011;
        }
      }
      return kE012;
    }
}

-(int)scheduleTask:(int)threshold{
    if (threshold <= 0) {
        return kE002;
    }
    if (_nodeList.count == 0) {
        return 0;//服务节点总数为0，无法调度，返回0
    }
    //获取运行中的任务
    NSMutableArray *runArray = [NSMutableArray array];
    for (NodeInfo *node in _nodeList) {
        if (node.tasks.count > 0) {
            [runArray addObjectsFromArray:node.tasks];
        }
    }
    if (runArray.count ==0 && _waitList.count == 0) {
        return 0;//没有任务存在，无法调度，返回0
    }
    int nodeCount = (int)_nodeList.count;
    int totalConsumption = 0;
    int min = 0;
    int max = 0;
    
    if (_waitList.count > 0) {
        for (TaskInfo *task in _waitList) {
            totalConsumption += task.consumption;
            max = MAX(max, task.consumption);
            min = MIN(min, task.consumption);
        }
    }
    int average = totalConsumption/nodeCount;
    BOOL flag = YES;
    for (int i = 0; i < _waitList.count; i++) {
        TaskInfo *task = _waitList[i];
        if (task.consumption != average) {
            flag = NO;
            break;
        }
    }
    if (flag) {
            for (int i = 0; i < _waitList.count; i++){
                TaskInfo *taskInfo = _waitList[i];
                for (int j= 0;j<_nodeList.count ; j++) {
                    NodeInfo *node = _nodeList[j];
                    [node addTask:taskInfo.taskId];
                }
            }
    }
    
    int itemCount = (int)_waitList.count/nodeCount;
    return kE013;
}

-(int)queryTaskStatus:(NSMutableArray<TaskInfo *> *)tasks{
    return 0;
}

#pragma mark - private
- (NodeInfo *)nodeInfoForKey:(int)nodeId{
    if (nodeId <= 0 || _nodeList.count == 0) {
        return nil;
    }
    for (NodeInfo *node in _nodeList) {
        if (node.nodeId == nodeId) {
            return node;
        }
    }
    return nil;
}
- (TaskInfo *)taskInfoInWaitListWithId:(int)taskId{
    if (taskId <= 0 || _waitList.count == 0) {
        return nil;
    }
    for (TaskInfo *task in _waitList) {
        if (task.taskId == taskId) {
            return task;
        }
    }
    return nil;
}

@end
