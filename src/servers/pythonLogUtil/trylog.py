#!/bin/env python2.7
#-*- coding=utf-8 -*_

#debug 调试信息
#info 基本信息
#warning 警告信息
#error 错误信息
#critical 严重错误信息

class Loger:

    """

    """

    #Loger Initialization
    def __init__(self, FILE_PATH,
                       LOG_LOWEST_RANK = "debug",
                       LOG_PATH = "log",
                       LOG_FILE_NAME = "bubbles.log",
                       CONSOLE_RANK = "info",
                       LOG_FILE_RANK = "warning"
                       ):
        # Create a logger
        logger = logging.getLogger('mylogger')
        logger.setLevel(logging.LOG_LOWEST_RANK)

        
        # Create a logger hanlde，put the logs to the log file
        fh = logging.FileHandler(FILE_PATH + '/' + LOG_PATH + '/' + LOG_FILE_NAME)
        fh.setLevel(logging.LOG_FILE_RANK)

        # Create another logger hanlde，Put the logs on the console
		ch = logging.StreamHandler()
        ch.setLevel(logging.CONSOLE_RANK)


        # define the format handler of output 
        formatter_log = logging.Formatter(fmt='[%(asctime)s] - %(name)s - %(levelname)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S.%f')
        formatter_con = logging.Formatter(fmt='[%(asctime)s %(levelname)s] > %(message)s', datefmt='%H:%M:%S')

        fh.setFormatter(formatter_log)
        ch.setFormatter(formatter_con)

        # 给logger添加handler
        logger.addHandler(fh)
        logger.addHandler(ch)

    def D(DEBUG):

        self.logger.debug(DEBUG)

    def I(INFO):

        self.logger.info(INFO)

    def W(WARNING):

        self.logger.warning(WARNING)

    def E(ERROR):

        self.logger.error(ERROR)

    def C(CRITICAL):

        self.logger.critical(CRITICAL)


from Loger import Loger
L=Loger('./')
L.D('DEBUG test')
L.I('INFO test')
L.W('warning test')
L.E('ERROR test')
L.C('CRITICAL test')



zm
zi zo
