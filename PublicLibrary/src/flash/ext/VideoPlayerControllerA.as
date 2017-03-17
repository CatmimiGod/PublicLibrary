package flash.ext
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.VideoPlayerEvent;
	import flash.geom.Rectangle;
	import flash.net.Socket;
	import flash.utils.setTimeout;
	
	[Event(name="VideoPlayerEvent.UPDATE", type="flash.events.VideoPlayerEvent")]
	[Event(name="VideoPlayerEvent.CUE_POINT", type="flash.events.VideoPlayerEvent")]
	
	/**
	 *	C# VideoPlayer 控制对象
	 * 	@author Administrator
	 */	
	public final class VideoPlayerControllerA extends EventDispatcher
	{
		private var _port:int;
		private var _address:String;
		
		private var _socket:Socket;
		private var _queue:Vector.<String>
		private var _updateVideoState:Boolean;
		
		private var _stateInfo:Object;
		private var _cuePositions:Vector.<Number>;
		
		/**
		 * Constructor.
		 * @param port	视频窗体端口号
		 * @param updateVideoState	是否需要时实返回视频播放状态及相关数据
		 */
		public function VideoPlayerControllerA(updateVideoState:Boolean = false, port:int = 2010, address:String = "127.0.0.1")
		{
			_port = port;
			_address = address;
			_updateVideoState = updateVideoState;
			
			_queue = new Vector.<String>();
			_cuePositions = new Vector.<Number>();			
			_stateInfo = {id:-1, rect:new Rectangle(), visible:true, state:0, position:0, duration:0, volume:100, rate:1, mute:false, cuePoint:""};
			
			_socket = new Socket(_address, _port);
			_socket.addEventListener(Event.CLOSE, onSocketEventHandler);
			_socket.addEventListener(Event.CONNECT, onSocketEventHandler);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, onSocketEventHandler);
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketEventHandler);
		}
		private function onSocketEventHandler(e:Event):void
		{
			switch(e.type)
			{
				case Event.CLOSE:
				case IOErrorEvent.IO_ERROR:
					trace("VideoPlayer Connect...", e.type);
					setTimeout(_socket.connect, 500, _address, _port);
					break;
				
				case Event.CONNECT:
					sendQueues();
					sendData("getVideoState");
					sendData("getWindowState");
					break;
				
				case ProgressEvent.SOCKET_DATA:
					analyseData(_socket.readUTFBytes(_socket.bytesAvailable));
					break;
			}
		}
		/**	分析接收的数据	*/
		protected function analyseData(value:String):void
		{
			//trace(value);
			var data:Array = value.split(";");
			var len:int = data.length;
			
			var obj:Array;
			var prop:String;
			
			for(var i:int = 0; i < len; i ++)
			{
				if(data[i].indexOf(":") == -1)	break;
				
				obj = data[i].split(":");
				prop = obj[0];
				
				if(!_stateInfo.hasOwnProperty(prop))
					break;
				
				switch(prop)
				{
					case "id":
					case "rate":
					case "state":
					case "volume":
					case "position":
					case "duration":
						_stateInfo[prop] = Number(obj[1]);
						
						if(prop == "position" && _updateVideoState && _stateInfo.state == 0x03 && _stateInfo.cuePoint != "")
							analyseCuePoint(_stateInfo.position);
						break;
					
					case "mute":
					case "visible":
						_stateInfo[prop] = obj[1].toLowerCase() == "true";
						break;
					
					case "rect":
						var r:Array = obj[1].split(",");
						if(r.length == 4)
						{
							_stateInfo.rect.x = Number(r[0]);
							_stateInfo.rect.y = Number(r[1]);
							_stateInfo.rect.width = Number(r[2]);
							_stateInfo.rect.height = Number(r[3]);
						}
						break;
					
					default:
						_stateInfo[prop] = obj[1].toLowerCase();
				}
			}
			
			this.dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.UPDATE));
			
			if(_updateVideoState && _stateInfo.state > 0x02)
				sendData("getVideoState");
		}
		
		/**	分析提示点	*/
		private function analyseCuePoint(position:Number):void
		{
			//trace("analyseCuePoint:" + position);
			var cuePoints:Array = _stateInfo.cuePoint.split(",");
			var count:uint = cuePoints.length;
			if(count <= 0)	return;
			
			if(_cuePositions.length != count)
				_cuePositions.length = count;
			
			var dec:uint;
			var cp:Number;
			var pos:Number;
			
			for(var i:int = 0; i < count; i ++)
			{
				dec = getDecimalPlaces(cuePoints[i]);	//获取原设置节点的小数点位
				pos = Math.floor(position * dec) / dec;	//计算当前位置的数据点，与设置的小数点位相同
				cp = Number(cuePoints[i]);				
				
				if(cp == pos && _cuePositions[i] != pos)	//计算值是否相等，如果相等就记录下来，如果不相等则记录为0
				{
					_cuePositions[i] = pos;
					//trace("节点了", _cuePositions[i], _stateInfo.position);
					this.dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.CUE_POINT, false, false, cp, i, _stateInfo.position, _stateInfo.id));
					break;
				}
				else
				{
					if(_cuePositions[i] != pos)
						_cuePositions[i] = 0;
				}
			}
		}
		
		[inline]
		protected static function getDecimalPlaces(num:String):uint
		{
			var dec:int = 1;
			var len:int = num.indexOf(".") != -1 ? num.split(".")[1].length : 0;
			
			if(len > 0)
			{
				for(var i:int = 0; i < len; i ++)
					dec *= 10;
			}
			
			return dec;
		}
		
		/**	发送URL变量数据 	 @param value	 */		
		protected function sendData(value:String):void
		{
			if(_socket == null)		return;
			
			if(_socket.connected)
			{
				//trace(value);
				_socket.writeUTFBytes(value);
				_socket.flush();
			}
			else
			{
				_queue.unshift(value);
			}
		}
		
		/**	发送失败的命令，重新排队发送	*/
		protected function sendQueues():void
		{
			if(_queue.length == 0)	return;
			trace("sendQueues...");
			var queue:Vector.<String> = _queue.concat();
			var count:int = queue.length;
			
			_queue = new Vector.<String>();
			for(var i:int = count - 1; i >= 0; i --)
			{
				trace(queue[i]);
				//sendData(queue[i]);
				setTimeout(sendData, 100 * i, queue[i]);
				queue.splice(i, 1);
			}
		}
		
		/**	关闭视频窗体并清理对象内存	*/
		public function dispose():void
		{
			sendData("dispose");
			
			_queue = null;
			_stateInfo = null;
			
			_socket.removeEventListener(Event.CLOSE, onSocketEventHandler);
			_socket.removeEventListener(Event.CONNECT, onSocketEventHandler);
			_socket.removeEventListener(IOErrorEvent.IO_ERROR, onSocketEventHandler);
			_socket.removeEventListener(ProgressEvent.SOCKET_DATA, onSocketEventHandler);
			
			if(_socket.connected)	_socket.close();
			_socket = null;
		}
		
		//Window
		//----------------------------------------------------------------------
		/**
		 *	设置尺寸大小 
		 * @param rect
		 */		
		public function setSize(rect:Rectangle):void
		{
			_stateInfo.rect = rect;
			sendData("setSize:" + rect.x + "," + rect.y + "," + rect.width + "," + rect.height);
		}
		
		/**视频窗体置底*/
		public function windowToBack():void{	sendData("windowToBack");		}
		
		/**视频窗体置顶*/
		public function windowToFront():void{		sendData("windowToFront");		}
		
		/**	设置窗体的可见性	*/
		public function get visible():Boolean{	return _stateInfo.visible;	}
		public function set visible(value:Boolean):void
		{
			_stateInfo.visible = value;
			sendData("visible:" + _stateInfo.visible.toString());
		}
		
		
		//Video
		//-----------------------------------------------------------------
		/**	加载视频并播放	*/
		public function load(url:String, autoPlay:Boolean = false, loop:Boolean = false):void	
		{		
			sendData("loop:" + loop.toString());
			sendData("autoPlay:" + autoPlay.toString());
			
			sendData("load:" + url);
		}
		
		/**	加载视频列表配置的视频序号	*/
		public function loadIndex(id:int):void{		sendData("loadIndex:" + id);		}
		
		/** 播放视频*/
		public function play():void{		sendData("play");		}
		/**	暂停视频	*/
		public function pause():void{		sendData("pause");		}
		/**	停止视频	*/
		public function stop():void{		sendData("stop");		}
		
		/**	快进	*/
		public function fastForward():void{		sendData("fastForward");		}		
		/**	快退		*/
		public function fastReverse():void{		sendData("fastReverse");		}
		
		/**	设置视频音量 */		
		public function get volume():int{		return _stateInfo.volume;		}
		public function set volume(value:int):void
		{
			if(value >= 0 && value <= 100)
			{
				_stateInfo.volume = value;
				sendData("volume:" + _stateInfo.volume);
			}
		}
		
		/**	设置是否静音 */		
		public function get mute():Boolean{		return _stateInfo.mute;		}
		public function set mute(value:Boolean):void
		{
			_stateInfo.mute = value;
			sendData("mute:" + value);
		}
		
		/**	video position	*/
		public function get position():Number{	return _stateInfo.position;	}
		public function set position(value:Number):void
		{
			if(value >= 0)
			{
				_stateInfo.position = value;
				sendData("position:" + _stateInfo.position);
			}
		}
		
		/** 比率，速度*/
		public function get rate():uint{	return _stateInfo.rate;		}
		public function set rate(value:uint):void
		{
			_stateInfo.rate = value;
			sendData("rate:" + _stateInfo.rate);
		}
		
		/**	视频的持续时间	*/
		public function get duration():Number	{	return _stateInfo.duration;		}
		
		/**	视频是否正在播放	*/
		public function get playing():Boolean{	return _stateInfo.state == 0x03;	}
		
		/**	视频播放状态	*/
		public function get videoState():uint{	return _stateInfo.state;		}
	}
}