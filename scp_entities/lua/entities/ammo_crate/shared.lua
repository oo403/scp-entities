AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName   = "Skrzynia Amunicji"

ENT.Spawnable = true

ENT.Category = "Podstawowe"

ENT.HoverLerp = 0

function ENT:Initialize()

    self:SetModel("models/ammo_crate.mdl")

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
end

function ENT:Think()
    self:NextThink(CurTime())
    self:FrameAdvance(FrameTime())
    return true
end

function ENT:Use(player, caller)
    if SERVER then
        self.NextUse = self.NextUse or 0
        local delay = 0.5

        local weapon = player:GetActiveWeapon()

        if player:IsPlayer() and CurTime() > self.NextUse and weapon != "weapon_crowbar" then
            local weapon = player:GetActiveWeapon()
            if not weapon then return end

            local seq = self:LookupSequence("open")
            if seq == -1 then return end

            self:ResetSequence(seq)
            self:SetCycle(0)
            self:ResetSequenceInfo()

            local seqLength = self:SequenceDuration(seq)

            self.NextUse = CurTime() + seqLength

            timer.Simple(seqLength, function()
                if IsValid(player) and IsValid(self) then
                    local ammoType = weapon:GetPrimaryAmmoType()
                    player:GiveAmmo(180, ammoType, true)
                    player:EmitSound("items/ammo_pickup.wav", 75, 100, 1, CHAN_ITEM)
                end
            end)
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

    
    local pos = self:GetPos() + self:GetUp() * 16
    local angle = self:GetAngles()

    angle:RotateAroundAxis( angle:Up(), 90 )

    if self.HoverLerp > 0.01 then
        cam.Start3D2D(pos, angle, 0.03 * self.HoverLerp)
            draw.RoundedBox(10, -600, -80, 1200, 300, Color(63, 75, 95))
            draw.SimpleText("SKRZYNIA AMUNICJI", "TextFont", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("NACIŚNIJ E, ABY UŻYĆ", "TextFont", 0, 100, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end    