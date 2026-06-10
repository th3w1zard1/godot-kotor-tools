@tool
extends "../gff_resource.gd"
class_name PTHResource

const KotorPTHDocument := preload("../documents/kotor_pth_document.gd")


func get_tag() -> String:
	return (create_document() as KotorPTHDocument).get_tag()


func get_point_field_name() -> String:
	return (create_document() as KotorPTHDocument).get_point_field_name()


func get_point_count() -> int:
	return (create_document() as KotorPTHDocument).get_point_count()


func get_point_records() -> Array[Dictionary]:
	return (create_document() as KotorPTHDocument).get_point_records()


func get_connection_field_name() -> String:
	return (create_document() as KotorPTHDocument).get_connection_field_name()


func get_connection_count() -> int:
	return (create_document() as KotorPTHDocument).get_connection_count()


func get_connection_records() -> Array[Dictionary]:
	return (create_document() as KotorPTHDocument).get_connection_records()


func set_point_position(index: int, x: float, y: float, z: Variant = null) -> bool:
	return (create_document() as KotorPTHDocument).set_point_position(index, x, y, z)


func set_connection_destination(connection_index: int, target_index: int) -> bool:
	return (create_document() as KotorPTHDocument).set_connection_destination(connection_index, target_index)


func add_connection(source_index: int, target_index: int) -> int:
	return (create_document() as KotorPTHDocument).add_connection(source_index, target_index)


func remove_connection(connection_index: int) -> bool:
	return (create_document() as KotorPTHDocument).remove_connection(connection_index)


func add_point(x: float, y: float, z: float = 0.0) -> int:
	return (create_document() as KotorPTHDocument).add_point(x, y, z)


func remove_point(index: int) -> bool:
	return (create_document() as KotorPTHDocument).remove_point(index)


func capture_topology_snapshot() -> Dictionary:
	return (create_document() as KotorPTHDocument).capture_topology_snapshot()


func restore_topology_snapshot(snapshot: Dictionary) -> bool:
	return (create_document() as KotorPTHDocument).restore_topology_snapshot(snapshot)


func _create_document():
	return KotorPTHDocument.new().setup(file_type, gff_data, self)
