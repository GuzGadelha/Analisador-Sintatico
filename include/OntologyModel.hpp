#ifndef ONTOLOGY_MODEL_HPP
#define ONTOLOGY_MODEL_HPP

#include <string>
#include <vector>
#include <map>
#include <memory>

namespace Tonto {

struct Attribute {
    std::string name;
    std::string type;
    std::vector<std::string> meta_attributes;
    int line = 0;
    int col = 0;
};

struct Relation {
    std::string name;
    std::string stereotype;
    bool is_internal = false;
    std::string source_class; 
    std::string target_class; 
    std::string source_cardinality;
    std::string target_cardinality;
    std::string rel_operator; 
    std::vector<std::string> meta_attributes;
    int line = 0;
    int col = 0;
};

struct OntoClass {
    std::string name;
    std::string stereotype;
    std::string parent_class; 
    std::vector<Attribute> attributes;
    std::vector<Relation> internal_relations;
    int line = 0;
    int col = 0;
};

struct DataType {
    std::string name;
    std::vector<Attribute> fields;
    int line = 0;
    int col = 0;
};

struct EnumClass {
    std::string name;
    std::vector<std::string> literals;
    int line = 0;
    int col = 0;
};

struct GenSet {
    std::string name;
    std::string general_class;
    std::vector<std::string> specific_classes;
    std::vector<std::string> restrictions; // "disjoint", "complete", "overlapping", "incomplete"
    bool is_inline = false;
    int line = 0;
    int col = 0;
};

struct Instance {
    std::string name;
    std::string class_type;
    int line = 0;
    int col = 0;
};

struct Package {
    std::string name;
    std::vector<OntoClass> classes;
    std::vector<DataType> datatypes;
    std::vector<EnumClass> enums;
    std::vector<GenSet> gensets;
    std::vector<Relation> external_relations;
    std::vector<Instance> instances;
    int line = 0;
    int col = 0;
};

class Ontology {
private:
    std::vector<Package> packages;
    std::string active_package_name = "default";
    std::vector<std::string> native_types_recorded;

    Package& get_or_create_active_package();

public:
    Ontology();

    void enter_package(const std::string& name, int line, int col);
    void add_class(const OntoClass& cls);
    void add_datatype(const DataType& dt);
    void add_enum(const EnumClass& en);
    void add_genset(const GenSet& gs);
    void add_relation(const Relation& rel);
    void add_instance(const Instance& inst);
    void record_native_type(const std::string& type_name);

    const std::vector<Package>& get_packages() const;
    const std::vector<std::string>& get_native_types() const;

    int get_total_packages() const;
    int get_total_classes() const;
    int get_total_attributes() const;
    int get_total_internal_relations() const;
    int get_total_external_relations() const;
    int get_total_gensets() const;
    int get_total_datatypes() const;
    int get_total_enums() const;
    int get_total_instances() const;

    void clear();
};

extern Ontology g_ontology;

} 

#endif
