AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName   = "Szafa na HAZMAT"

ENT.Spawnable = true

ENT.Category = "Podstawowe"

ENT.HoverLerp = 0

function ENT:Initialize()

    self:SetModel("models/hazmat_locker.mdl")

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:ResetSequenceInfo()
    self:FrameAdvance(0)

    local phys = self:GetPhysicsObject()

    if ( IsValid(phys) ) then
        phys:Wake()
    end

    if ( SERVER ) then
        self:PrecacheGibs()
    end

    if SERVER then
    hazmat_ragdoll = ents.Create("prop_dynamic")
    hazmat_ragdoll:SetModel("models/cod_aw_hazmat_player.mdl")
    hazmat_ragdoll:SetPos(self:GetPos() + Vector(0, 0, 5))
    hazmat_ragdoll:SetAngles(self:GetAngles() + Angle(90, 0, 0))
    hazmat_ragdoll:SetParent(self)
    hazmat_ragdoll:ResetSequence("idle")
    hazmat_ragdoll:SetUnFreezable(true)
    hazmat_ragdoll:Spawn()

    undo.Create("HazmatRagdoll")
        undo.AddEntity(hazmat_ragdoll)
        undo.SetPlayer(self:GetOwner())
    undo.Finish()   
    end 

end

if SERVER then
    util.AddNetworkString("HazmatRemoveSmoke")

    local playerOriginalModel = {}    

    hook.Add("PlayerSay", "HazmatRemoveCommand", function(ply, msg)
        msg = string.lower(msg)

        if msg == "/zdejmijhazmat" then
            local originalModel = playerOriginalModel[ply:SteamID()]
            if originalModel then
                ply:SetModel(originalModel)
                ply:ChatPrint("Zdjąłeś HAZMAT!")
                ply:EmitSound("items/ammo_pickup.wav", 75, 100, 1, CHAN_ITEM)

                playerOriginalModel[ply:SteamID()] = nil
            else
                ply:ChatPrint("Nie masz założonego HAZMAT!")
            end
            return ""
        end
    end)

function ENT:Think()
    self:NextThink(CurTime())
    self:FrameAdvance(FrameTime())
    return true
end

function ENT:Use( player, caller )
    if ( SERVER ) then
        local delay = 0.5
        self.NextUse = self.NextUse or 0

        local playerModelBefore = player:GetModel()
        
        if ( player:IsPlayer() and CurTime() > self.NextUse and playerModelBefore != "models/cod_aw_hazmat_player.mdl") then
            self:ResetSequence(self:LookupSequence("open"))
            self:SetCycle(0)
            self:ResetSequenceInfo()

            local seqLength = self:SequenceDuration(self:LookupSequence("open"))

            timer.Simple(seqLength - 2, function()
                playerOriginalModel[player:SteamID()] = playerModelBefore
                if IsValid(hazmat_ragdoll) then
                    hazmat_ragdoll:Remove()
                end    
                player:SetModel("models/cod_aw_hazmat_player.mdl")
                player:EmitSound("items/ammo_pickup.wav", 75, 100, 1, CHAN_ITEM)
                player:ChatPrint("Założyłeś HAZMAT! Aby zdjąć HAZMAT, użyj komendy /zdejmijhazmat")
                timer.Simple(2, function()
                    hazmat_ragdoll2 = ents.Create("prop_dynamic")
                    hazmat_ragdoll2:SetModel("models/cod_aw_hazmat_player.mdl")
                    hazmat_ragdoll2:SetPos(self:GetPos() + Vector(0, 0, 5))
                    hazmat_ragdoll2:SetAngles(self:GetAngles() + Angle(90, 0, 0))
                    hazmat_ragdoll2:SetParent(self)
                    hazmat_ragdoll2:ResetSequence("idle")
                    hazmat_ragdoll2:SetUnFreezable(true)
                    hazmat_ragdoll2:Spawn()
                end)
                if IsValid(hazmat_ragdoll2) then
                    hazmat_ragdoll2:Remove()
                end
            end)    

            self.NextUse = CurTime() + delay
        end
    end
end
end


if CLIENT then
    surface.CreateFont("TextFont", {
        font = "Roboto",
        size = 120,
        weight = 1500,
        antialias = true,
        outline = false,
    })
end 

function ENT:Draw() 

    self:DrawModel()

    local ply = LocalPlayer()
    local distance = ply:GetPos():Distance(self:GetPos())

    if distance <= 100 then
        local target = 1 or 0
        self.HoverLerp = Lerp(FrameTime() * 8, self.HoverLerp, target)
    else
        self.HoverLerp = Lerp(FrameTime() * 8, self.HoverLerp, 0)
    end

    
    local pos = self:GetPos() + self:GetForward() * 18 + self:GetUp() * 55
    local angle = self:GetAngles()

    angle:RotateAroundAxis( angle:Up(), -270 )
    angle:RotateAroundAxis( angle:Forward(), 90 )

    if self.HoverLerp > 0.01 then
        cam.Start3D2D(pos, angle, 0.03 * self.HoverLerp)
            draw.RoundedBox(10, -600, -80, 1200, 300, Color(63, 75, 95))
            draw.SimpleText("SZAFA NA HAZMAT", "TextFont", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("NACIŚNIJ E, ABY UŻYĆ", "TextFont", 0, 100, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end    