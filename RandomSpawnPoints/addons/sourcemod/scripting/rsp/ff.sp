void FF_Update()
{
    if(GetConVarInt2(FRIENDLY_FIRE) == -1)
        return;

    if(!GetConVarBool2(ENABLE))
    {
        mp_friendlyfire.SetInt(0);
        return;
    }
    if(GetConVarInt2(MIN_POINTS) > Points.Size)
    {
        mp_friendlyfire.SetInt(0);
        return;
    }
    mp_friendlyfire.SetInt(1);
}
