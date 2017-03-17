package flash.media
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.JPEGEncoderOptions;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NetworkControllerEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.net.SocketServer;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	/**
	 *	MJPEG视频流服务端，未完成未优化
	 * @author Administrator
	 */	
	public class MJPEGVideoStream extends EventDispatcher
	{
		/**	要输出压缩的 显示 对象的区域	*/
		public var rectangle:Rectangle;
		
		//编码质量
		private var _quality:uint = 80;
		private var _compressor:JPEGEncoderOptions;
		
		private var _bytes:ByteArray;
		private var _bmpd:BitmapData;
		private var _source:DisplayObject;
		
		private var _fps:uint = 25;
		private var _timer:Timer;
		private var _socketServer:SocketServer;
		
		public function MJPEGVideoStream(source:DisplayObject, fps:uint = 25, localPort:int = 2011)
		{
			if(source == null)
				throw new ArgumentError("source不能为空");
			
			_bytes = new ByteArray();
			_compressor = new JPEGEncoderOptions(_quality);
			_bmpd = new BitmapData(source.width, source.height);
			
			_bmpd.lock();
			
			_fps = fps;
			_source = source;
			rectangle = _bmpd.rect;
			
			//_timer = new Timer(1000 / _fps);
			//_timer.addEventListener(TimerEvent.TIMER, onTimerEventHandler);
			//_timer.start();
			
			_socketServer = new SocketServer(localPort);
			_socketServer.addEventListener(NetworkControllerEvent.CLIENT_DATA, onSocketServerEventHandler);
		}
		private function onSocketServerEventHandler(e:Event):void
		{
			encode();
		}
		private function onTimerEventHandler(e:TimerEvent):void
		{
			encode();
		}
		
		private var _renderStart:Number = 0;
		private var _renderEnd:Number = 0;
		
		public var renderms:Number = 0;
		public var sendms:Number = 0;
		
		public function encode():void
		{
			//if(_socketServer.getClients().length <= 0)	return;
			
			//开始绘图编码
			_renderStart = getTimer();
			_bytes.clear();
			
			_bmpd.draw(_source);
			_bmpd.encode(rectangle, _compressor, _bytes);
			trace(_bytes.length);
			//结束绘图编码
			_renderEnd = getTimer();
			renderms = _renderEnd - _renderStart;
			
			_socketServer.sendByteArray(_bytes);
			//发送用时
			sendms = getTimer() - _renderEnd;
			this.dispatchEvent(new Event(Event.RENDER));
		}
		
		/**	编码质量 1-100 	*/
		public function get quality():uint{	return _quality;		}
		public function set quality(value:uint):void
		{
			_quality = Math.max(1, Math.min(100, value));
			_compressor.quality = _quality;
		}
		
		/**	帧频10-30	*/
		public function get fps():uint{		return _fps;		}
		public function set fps(value:uint):void
		{
			_fps = Math.max(10, Math.min(30, value));
			_timer.delay = 1000 / _fps;
		}
		
	}
}