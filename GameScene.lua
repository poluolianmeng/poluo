--
-- Author: Your Name
-- Date: 2015-06-04 15:29:53

--setTouchSwallowEnabled(true)
--它的作用就是是否继续传递触摸消息，在绘制节点的时候，越是在屏幕上方，
--就是zOrder越大，越优先接收到触摸事件，如果设置吞噬，那么在它下方的
--节点都不会接收到触摸消息了。默认如果不设置则quick自动设置为true。


local scheduler = require("framework.scheduler")
local PauseLayer = require("app.scenes.PauseLayer")
local WinLayer = require("app.Class.WinLayer")
local LoseLayer = require("app.Class.LoseLayer")
local SetLayer = require("app.scenes.setLayer")


local GameScene = class("GameScene", function()
    return display.newPhysicsScene()
end)

local scenenum
local chapternum

function GameScene:ctor()
	scenenum = ModifyData.getSceneNumber()--获取场景数
    chapternum = ModifyData.getChapterNumber()--获取关卡数
    print("选择场景数是",scenenum)
    print("选择关卡数是",chapternum)
    --表
    local tb = PublicData.SCENETABLE

	--设置屏幕范围
	self._screenRect=cc.rect(0,0,display.width,display.height)
	--星星个数
	self._starNumber=0

	--背景
	local bg = cc.Sprite:create("background"..scenenum..".png")
	bg:pos(display.cx, display.cy)
	:addTo(self)

	--暂停
	local pauseBtn = cc.ui.UIPushButton.new("pause.png", {scale9=true})
	pauseBtn:pos(display.left+50, display.top-50)
	pauseBtn:onButtonClicked(function ( event )
		cc.Director:getInstance():pause()--暂停
		--暂停界面
		local layer = PauseLayer.new()
		layer:setPosition(cc.p(50,display.height-50))
		self:addChild(layer,2)
	end)
	self:addChild(pauseBtn,2)


	--创建世界
	self:initWorld()

	--加载ui场景
	print("加载的场景"..scenenum)
	local widget = cc.uiloader:load("ui/Level_"..scenenum.."_"..chapternum..".ExportJson")
	widget:setPosition(cc.p(0,0))
	self:addChild(widget,1)

	--房子
	self._house=cc.uiloader:seekNodeByName(widget, "house")  --从场景布置中获取房子
	local g = cc.ParticleSpiral:create() --星云粒子效果
	g:setPosition(self._house:getPosition())
	self:addChild(g)

	--将星星加入到表中
	self._starTB = {}
	for i=1,3 do
		local star = cc.uiloader:seekNodeByName(widget, "star"..i)  --从场景布置中获取星星
		table.insert(self._starTB,star)
	end

	local itemsTB = {}
	local itemsBodyTB = {}
	local body

	--创建刚体
	for i=1,tb[scenenum][chapternum].num do

		local item = cc.uiloader:seekNodeByName(widget,"Image_"..i)  --从场景布置中获取物体

		table.insert(itemsTB,item)
		table.insert(itemsBodyTB,body)

		if item:getTag()==301 then  --点击可消除的物体
			body = cc.PhysicsBody:createEdgeBox(cc.size(item:getContentSize().width, item:getContentSize().height))
			body:getShape(0):setRestitution(0.5)  --设置物体的恢复力
		elseif item:getTag()==601 then --蜗牛
			self._snail = item
			body = cc.PhysicsBody:createCircle(item:getContentSize().width/2)
			body:getShape(0):setRestitution(0.5) 
			body:setMass(20)  -- 设置质量
		elseif item:getTag()==106 then  --石头
			body = cc.PhysicsBody:createCircle(item:getContentSize().width/2-10)
			body:getShape(0):setRestitution(0.5)
		elseif item:getTag()==107 then  --蘑菇
			body = cc.PhysicsBody:createEdgeBox(item:getContentSize())
			body:setMass(0)
			body:getShape(0):setRestitution(2.8)
		elseif item:getTag()==401 then  --刺
			body = cc.PhysicsBody:createEdgeBox(item:getContentSize())
			body:getShape(0):setRestitution(0.5)
		elseif item:getTag()==109 then  --三角转 
			item:setAnchorPoint(cc.p(0,0))
			local width = item:getContentSize().width
			local height = item:getContentSize().height
			local arr = {cc.p(-width/2,-height/2),cc.p(-width/2,height/2),cc.p(width/2,-height/2)}
			body = cc.PhysicsBody:createEdgePolygon(arr) --构建多边形
			body:setMass(0)
			body:getShape(0):setRestitution(0.5)
		elseif item:getTag()==108 then  --椰子
			body = cc.PhysicsBody:createBox(item:getContentSize())
			body:setMass(100)
			body:getShape(0):setRestitution(0.5)
		elseif item:getTag()==201 then  --不可消
			body = cc.PhysicsBody:createEdgeBox(item:getContentSize())
			body:getShape(0):setRestitution(0.5)
		end

		body:getShape(0):setFriction(0.4)--设置摩擦力
		body:setGroup(item:getTag())--碰撞类型值
        body:setContactTestBitmask(1) --接触(触发检测函数);
		item:setPhysicsBody(body)  --body:bind(item)--绑定

		if item:getTag()==109 then
			--body:setPosition(ccp(item:getPositionX()-item:getContentSize().width/2, item:getPositionY()-item:getContentSize().height/2))
		end
		if item:getTag()==601 then
			self._snailbody = body
		end
		if item:getTag()==107 then
			local png = "mogu.png"
			local plist = "mogu.plist"
			display.addSpriteFrames(plist,png)
			--
			self._sp = display.newSprite("#mogu1.png")
			self._sp:setPosition(item:getPosition())
			self._sp:setRotation(item:getRotation())
			self:addChild(self._sp,1)
			local frames = display.newFrames("mogu%d.png", 1, 5)
			local animate = display.newAnimation(frames, 0.3)
			self._sp:playAnimationForever(animate, 0.1)
		end		
	end
	--触摸
	local isMove = false
	-- self:setTouchSwallowEnabled(false)
	-- self:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
	self:setTouchEnabled(true)
	self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function ( event )
		if event.name == "began" then
			print("TouchBegin")
			isMove = false
			return true
		elseif event.name == "moved" then
			print("TouchMoved")
			isMove = true
		elseif event.name == "ended" then
		isMove = false
			if isMove == false then
				for k,v in pairs(itemsTB) do
					print("Touchbefore")
					local p = cc.p(event.x,event.y)
					local rect = self:newRect(v)
					if v:getTag() == 301 and cc.rectContainsPoint(rect,p) then
						v:removeFromParent()
						table.remove(itemsTB,k)
						table.remove(itemsBodyTB,k)
						print("touched")
					end
				end
			end
		end
	end)

	--右上角得分星星
	self._xx = display.newSprite("0getstar.png")
	self._xx:setPosition(cc.p(display.right-self._xx:getContentSize().width/2, display.top-self._xx:getContentSize().height/2))
	self:addChild(self._xx,2)

	--label：场景数-关卡数label
   display.newTTFLabel({
      text = scenenum .."-"..chapternum,
	  color = cc.c3b(100, 100, 100),
	  size = 40,
   	}):pos(display.right-100,display.top-80)
	:addTo(self,2)

	--碰撞检测:蜗牛和刺
	self:collisionListener()

	--调度update
	self._schedule = scheduler.scheduleGlobal(handler(self, self.update),0.1)
end

--重写一个新的rect
function GameScene:newRect(v)
	local size = v:getContentSize()
	local x = v:getPositionX()
	local y = v:getPositionY()
	local rect = cc.rect(x-size.width/2, y-size.height/2, size.width, size.height)
	return rect
end


--创建世界
function GameScene:initWorld(  )
	--世界
	self._world=self:getPhysicsWorld()
	self._world:setGravity(cc.p(0,-1000))--设置重力

	--地面刚体
	local bottomsp = display.newSprite("caocong.png")
	local scaleX = display.width/bottomsp:getContentSize().width
	bottomsp:setScale(scaleX)
	self:addChild(bottomsp)

	local bottom =cc.PhysicsBody:createEdgeBox(cc.size(display.width,30))
	bottom:getShape(0):setFriction(0.9)
	bottom:getShape(0):setRestitution(0.5)
    bottom:setMass(0)
    bottomsp:pos(display.cx, 15)
	bottomsp:setPhysicsBody(bottom)

	--刚体调试
	self._world:setDebugDrawMask(cc.PhysicsWorld.DEBUGDRAW_ALL)
end

--碰撞检测：蜗牛和刺
function GameScene:collisionListener(  )
	--注册碰撞监听事件
	print("Listerbegin")
   --local contactListener  = cc.EventListenerPhysicsContact:create()

    local function onContactBegin(contact)
   	    print("碰撞")
        local node1=contact:getShapeA():getBody():getNode()
        print("node1:"..node1:getTag())
        local node2=contact:getShapeB():getBody():getNode()
        if (node1:getTag()==601 and node2:getTag()==401) or (node1:getTag()==401 and node2:getTag()==601) then
			local loseLayer = LoseLayer.new()
	  		scheduler.unscheduleGlobal(self._schedule)
  			-- self._touchLayer:removeFromParent()
 			loseLayer:setPosition(cc.p(0, 200))
 			self._snail:removeSelf()
 			transition.moveTo(loseLayer,{time = 0.7, y = 0})
  			self:addChild(loseLayer,2)
        end
      return true 
    end
    local contactListener = cc.EventListenerPhysicsContact:create()
    contactListener:registerScriptHandler(onContactBegin, cc.Handler.EVENT_PHYSICS_CONTACT_BEGIN);
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(contactListener, self);
end

function GameScene:update(dt)
	
	--改变星星的数量
	local rect1 = self:newRect(self._snail)
	for k,v in pairs(self._starTB) do
		local rect2 = self:newRect(v)
		if cc.rectIntersectsRect(rect1,rect2 ) then
			--碰到星星时音效
			if SetLayer.isPlaySound then
			 	audio.playSound("yinxiao.wav", false)
			end 

			table.remove(self._starTB,k)
			v:removeFromParent()
			self._starNumber = self._starNumber+1

			--改变右上角得分星星的数量
			local texture =cc.Director:getInstance():getTextureCache():addImage(self._starNumber .."getstar.png")
			self._xx:setTexture(texture)
		end
	end

	
	--判断是否胜利（到达房子）
	local rect3 = self:newRect(self._house)
	if cc.rectIntersectsRect(rect1,rect3 )  then
        scheduler.unscheduleGlobal(self._schedule)--停止调度
		self._snail:setPosition(cc.p(self._house:getPositionX(), self._house:getPositionY()))
 		ModifyData.setStarNumber(self._starNumber)--修改星星的数量

 		--胜利界面
 		-- self._touchLayer:removeFromParent()
 		local layer = WinLayer.new()
 		layer:setPosition(cc.p(0, 200))
 		transition.moveTo(layer,{time = 0.7, y = 0})
 		self:addChild(layer,2)

 		--修改数据
 		self:modify()
	end

	--判断是否失败（滚出屏幕）
	if cc.rectContainsPoint(self._screenRect, cc.p(self._snail:getPositionX(),self._snail:getPositionY())) == false then
		--失败界面
		scheduler.unscheduleGlobal(self._schedule)
		local loseLayer = LoseLayer.new()
 		-- self._touchLayer:removeFromParent()
 		loseLayer:setPosition(cc.p(0, 200))
 		transition.moveTo(loseLayer,{time = 0.7, y = 0})
 		self:addChild(loseLayer,2)
	end
end

--修改数据
function GameScene:modify()
	local tb = PublicData.SCENETABLE
	if self._starNumber>tb[scenenum][chapternum].star  then
		tb[scenenum][chapternum].star = self._starNumber
		if self._starNumber == 3 then--星星数为3时解锁下一关
			if chapternum<#Data.SCENE[scenenum] then
				tb[scenenum][chapternum+1].lock = 0
			end
		end
	end
	
	local str = json.encode(tb)
	ModifyData.writeToDoc(str)
end

function GameScene:onEnter()
		--self._world:start()
end

function GameScene:onExit()
	scheduler.unscheduleGlobal(self._schedule)
end



return GameScene




