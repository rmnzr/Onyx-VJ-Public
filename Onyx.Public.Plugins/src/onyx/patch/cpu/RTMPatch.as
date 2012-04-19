package onyx.patch.cpu {
	
	import flash.events.AsyncErrorEvent;
	import flash.events.NetDataEvent;
	import flash.events.NetStatusEvent;
	import flash.geom.Matrix;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	import onyx.core.*;
	import onyx.display.*;
	import onyx.plugin.*;
	
	use namespace parameter;
	
	[Parameter(type='text',		id='host',			target='host')]
	[Parameter(type='text',		id='streamName',	target='streamName')]
	[Parameter(type='function',	id='connect',		target='connect')]
	
	[Parameter(id='scale',		target='contentTransform/matrix',		type='matrix/scale')]
	[Parameter(id='translate',	target='contentTransform/matrix',		type='matrix/translate')]
	[Parameter(id='rotation',	target='contentTransform/rotation',		type='number',				clamp='-1,1',		reset='0',	loop='true')]
	[Parameter(id='anchor',		target='contentTransform/anchor',		type='point',				clamp='0,1',		reset='0.5,0.5')]
	[Parameter(id='smoothing',	target='contentTransform/smoothing',	type='boolean')]

	final public class RTMPatch extends PluginPatch {
		
		/**
		 * 	@private
		 */
		parameter const contentTransform:ContentTransform		= new ContentTransform();
		
		/**
		 * 	@parameter
		 */
		parameter var host:String								= 'rtmp://localhost/live';
		
		/**
		 * 	@parameter
		 */
		parameter var streamName:String							= 'livestream';
		
		/**
		 * 	@private
		 * 	This should share connections!
		 */
		private var connection:NetConnection					= new NetConnection();
		
		/**
		 * 	@private
		 */
		private var stream:NetStream;
		
		/**
		 * 	@private
		 */
		private var video:Video;
		
		/**
		 * 	@private
		 */
		private var renderMatrix:Matrix;
		
		/**
		 * 	@public
		 */
		override public function initialize(context:IDisplayContext, path:IFileReference, content:Object):PluginStatus {
			
			// set to the same size as the blah blah
			dimensions.width	= context.width;
			dimensions.height	= context.height;
			
			return super.initialize(context, path, content);
		}
		
		/**
		 * 	@parameter
		 */
		parameter function connect():void {
			
			if (connection.uri !== host) {
				
				if (connection.connected) {
					clearConnections();
				}
				
				connection.addEventListener(NetStatusEvent.NET_STATUS, handleConnection);
				connection.connect(host);
				
			}
		}
		
		/**
		 * 	@private
		 */
		private function clearConnections():void {
			
			connection.close();
			if (stream) {
				stream.removeEventListener(AsyncErrorEvent.ASYNC_ERROR,		trace);
				stream.removeEventListener(NetStatusEvent.NET_STATUS,	handleStream);
				stream.close();
			}
			if (video) {
				video.attachNetStream(null);
				video = null;
			}
		}
		
		/**
		 * 	@private
		 */
		private function handleConnection(event:NetStatusEvent):void {
			Console.Log(Console.MESSAGE, 'RTMPatch: ' + event.info.code);
			switch (event.info.code) {
				case 'NetConnection.Connect.Success':
					
					stream = new NetStream(connection);
					stream.client	= this;
					stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, trace);
					stream.addEventListener(NetStatusEvent.NET_STATUS, handleStream);
					
					stream.bufferTime			= 0;
					stream.backBufferTime		= 0;
					stream.useHardwareDecoder	= true;
					stream.play(streamName);
					
					break;
			}
		}
		
		/**
		 * 	@public
		 */
		public function onMetaData(info:Object):void {
			
			Console.Log(Console.MESSAGE, 'RTMPatch: ' + info.width, info.height);
			
			invalid = true;
			
			if (video) {
				video.attachNetStream(null);
				video = null;
			}
			
			dimensions.width 	= info.width;
			dimensions.height	= info.height;
			
			contentTransform.initialize(context, dimensions);
			
			video	= new Video(info.width, info.height);
			// video.deblocking = 1;
			video.attachNetStream(stream);
			
		}
		
		/**
		 * 	@public
		 */
		override public function update(time:Number):Boolean {
			return true;
		}
		
		/**
		 * 	@private
		 */
		private function handleStream(e:NetStatusEvent):void {
			trace(e.info.code);
		}
		
		/**
		 * 	@public
		 */
		override public function validate():void {
			
			var updateMatrix:Boolean;
			
			// do we have invalid parameters?
			for (var i:String in invalidParameters) {
				
				// re-update our matrix
				switch (i) {
					case 'rotation':
					case 'scale':
					case 'translate':
						updateMatrix	= true;
						break;
				}
			}
			
			if (updateMatrix) {
				renderMatrix	= contentTransform.update(dimensions);
			}
			
			return super.validate();
		}
		
		/**
		 * 	@public
		 */
		override public function render(surface:IDisplaySurface):Boolean {
			if (video) {
				
				if (invalid) {
					validate();
				}

				surface.fillRect(surface.rect, 0);
				try {
					surface.draw(video, renderMatrix, null, null, null, contentTransform.smoothing);
				} catch (e:Error) {
					Console.Log(Console.ERROR, e.message);
				}
			}
			return true;
		}
		
		/**
		 * 	@public
		 */
		override public function dispose():void {
			
			if (stream) {
				
				stream.removeEventListener(AsyncErrorEvent.ASYNC_ERROR,		trace);
				stream.removeEventListener(NetStatusEvent.NET_STATUS,	handleStream);
				stream.close();
				stream = null;
				
			}
			
			if (connection) {
				connection.removeEventListener(NetStatusEvent.NET_STATUS, handleConnection);
				if (connection.connected) {
					connection.close();
				}
			}
			
			super.dispose();
			
		}

	}
}