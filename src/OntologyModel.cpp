#include "OntologyModel.hpp"
#include <algorithm>

namespace Tonto {

Ontology g_ontology;

Ontology::Ontology() {
    clear();
}

void Ontology::clear() {
    packages.clear();
    active_package_name = "default";
    native_types_recorded.clear();
}

Package& Ontology::get_or_create_active_package() {
    for (auto& pkg : packages) {
        if (pkg.name == active_package_name) {
            return pkg;
        }
    }
    Package new_pkg;
    new_pkg.name = active_package_name;
    packages.push_back(new_pkg);
    return packages.back();
}

void Ontology::enter_package(const std::string& name, int line, int col) {
    active_package_name = name;
    for (auto& pkg : packages) {
        if (pkg.name == name) {
            return;
        }
    }
    Package new_pkg;
    new_pkg.name = name;
    new_pkg.line = line;
    new_pkg.col = col;
    packages.push_back(new_pkg);
}

void Ontology::add_class(const OntoClass& cls) {
    get_or_create_active_package().classes.push_back(cls);
}

void Ontology::add_datatype(const DataType& dt) {
    get_or_create_active_package().datatypes.push_back(dt);
}

void Ontology::add_enum(const EnumClass& en) {
    get_or_create_active_package().enums.push_back(en);
}

void Ontology::add_genset(const GenSet& gs) {
    get_or_create_active_package().gensets.push_back(gs);
}

void Ontology::add_relation(const Relation& rel) {
    get_or_create_active_package().external_relations.push_back(rel);
}

void Ontology::add_instance(const Instance& inst) {
    get_or_create_active_package().instances.push_back(inst);
}

void Ontology::record_native_type(const std::string& type_name) {
    if (std::find(native_types_recorded.begin(), native_types_recorded.end(), type_name) == native_types_recorded.end()) {
        native_types_recorded.push_back(type_name);
    }
}

const std::vector<Package>& Ontology::get_packages() const {
    return packages;
}

const std::vector<std::string>& Ontology::get_native_types() const {
    return native_types_recorded;
}

int Ontology::get_total_packages() const {
    return static_cast<int>(packages.size());
}

int Ontology::get_total_classes() const {
    int total = 0;
    for (const auto& pkg : packages) {
        total += static_cast<int>(pkg.classes.size());
    }
    return total;
}

int Ontology::get_total_attributes() const {
    int total = 0;
    for (const auto& pkg : packages) {
        for (const auto& cls : pkg.classes) {
            total += static_cast<int>(cls.attributes.size());
        }
        for (const auto& dt : pkg.datatypes) {
            total += static_cast<int>(dt.fields.size());
        }
    }
    return total;
}

int Ontology::get_total_internal_relations() const {
    int total = 0;
    for (const auto& pkg : packages) {
        for (const auto& cls : pkg.classes) {
            total += static_cast<int>(cls.internal_relations.size());
        }
    }
    return total;
}

int Ontology::get_total_external_relations() const {
    int total = 0;
    for (const auto& pkg : packages) {
        total += static_cast<int>(pkg.external_relations.size());
    }
    return total;
}

int Ontology::get_total_gensets() const {
    int total = 0;
    for (const auto& pkg : packages) {
        total += static_cast<int>(pkg.gensets.size());
    }
    return total;
}

int Ontology::get_total_datatypes() const {
    int total = 0;
    for (const auto& pkg : packages) {
        total += static_cast<int>(pkg.datatypes.size());
    }
    return total;
}

int Ontology::get_total_enums() const {
    int total = 0;
    for (const auto& pkg : packages) {
        total += static_cast<int>(pkg.enums.size());
    }
    return total;
}

int Ontology::get_total_instances() const {
    int total = 0;
    for (const auto& pkg : packages) {
        total += static_cast<int>(pkg.instances.size());
    }
    return total;
}

} // namespace Tonto
