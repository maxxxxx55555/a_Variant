extends RefCounted
## Exact IEEE754 leaves supplement native text parsing inside the authenticated body.
## No object deserialization: only bounded paths, eight-byte floats and existing containers.
const MAX_PATCHES:int=10000
const MAX_DEPTH:int=26
static func capture(data:Dictionary)->Dictionary:
    var patches:Array[Dictionary]=[]
    var ok:bool=collect(data,[],patches,0)
    return {"ok":ok,"patches":patches}
static func collect(value:Variant,path:Array,patches:Array[Dictionary],depth:int)->bool:
    if depth>MAX_DEPTH:return false
    if value is float:
        var number:float=value
        if not is_finite(number) or patches.size()>=MAX_PATCHES:return false
        var bytes:PackedByteArray=PackedByteArray()
        if bytes.resize(8)!=OK:return false
        bytes.encode_double(0,number)
        patches.append({"route":path.duplicate(),"bits":bytes.hex_encode()})
    elif value is Dictionary:
        var fields:Dictionary=value
        var keys:Array=fields.keys()
        for key:Variant in keys:
            if not key is String:return false
        keys.sort()
        for key:String in keys:
            if not collect(fields[key],path+[key],patches,depth+1):return false
    elif value is Array:
        var items:Array=value
        for index:int in items.size():
            if not collect(items[index],path+[index],patches,depth+1):return false
    elif value!=null and not (value is int or value is bool or value is String):return false
    return true
static func restore(data:Dictionary,patches_value:Variant)->bool:
    if not patches_value is Array:return false
    var patches:Array=patches_value
    if patches.size()>MAX_PATCHES:return false
    var reconstructed:Dictionary=data.duplicate(true)
    var seen:Dictionary={}
    for patch_value:Variant in patches:
        if not patch_value is Dictionary:return false
        var patch:Dictionary=patch_value
        if patch.size()!=2 or not patch.get("route") is Array or not patch.get("bits") is String:return false
        var path:Array=patch.route
        var bits:String=patch.bits
        if path.is_empty() or path.size()>MAX_DEPTH or bits.length()!=16:return false
        for index:int in bits.length():
            if not bits.substr(index,1) in "0123456789abcdef":return false
        var canonical:Array=[]
        for segment:Variant in path:
            if segment is String:canonical.append(segment)
            elif segment is int or segment is float:
                var position:float=segment
                if not is_finite(position) or position<0 or position>50000 or position!=floorf(position):return false
                canonical.append(int(position))
            else:return false
        path=canonical
        var identity:String=JSON.stringify(path)
        if seen.has(identity):return false
        seen[identity]=true
        var bytes:PackedByteArray=bits.hex_decode()
        var exact:float=bytes.decode_double(0)
        if not is_finite(exact) or not assign_leaf(reconstructed,path,exact):return false
    for key:String in reconstructed:data[key]=reconstructed[key]
    return true
static func assign_leaf(data:Dictionary,path:Array,exact:float)->bool:
    var parent:Variant=data
    for index:int in path.size():
        var segment:Variant=path[index]
        var value:Variant
        if parent is Dictionary:
            var fields:Dictionary=parent
            if not segment is String or not fields.has(segment):return false
            value=fields[segment]
        elif parent is Array:
            var items:Array=parent
            # JSON paths decode integral indices as floats; ConfigFile retains integers.
            if not (segment is int or segment is float):return false
            var position:float=segment
            if not is_finite(position) or position<0 or position>=items.size() or position!=floorf(position):return false
            segment=int(position)
            value=items[segment]
        else:return false
        if index==path.size()-1:
            if not (value is int or value is float):return false
            var parsed:float=value
            # The supplement may repair parser rounding only, never change the stated value.
            if not is_finite(parsed) or absf(parsed-exact)>maxf(1.0,absf(exact))*1.0e-14:return false
            if parent is Dictionary:
                var fields:Dictionary=parent
                fields[segment]=exact
            else:
                var items:Array=parent
                items[segment]=exact
            return true
        parent=value
    return false
