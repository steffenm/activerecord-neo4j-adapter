namespace :neo4j_rest do
  desc 'Migrates models from an older scheme which relied on indexes to a new scheme with serializable model attributes'
  task :migrate_models => :environment do
    p 'Connecting models to root node'
    # Construct a query to get all model nodes, map them to the root
    query = model_nodes_query = "model_nodes = g.idx('model_index')[[type:'model']];"
    query += "root = g.v(root_node_id);"
    query += "model_nodes.each{g.addEdge(root, it, 'models')};"
    query += model_nodes_query

    model_nodes = Neo4jRestIllustrator.connection.execute_gremlin query, "Connecting model nodes to root", :root_node_id => Neo4jRestIllustrator.connection.root

    spinner_steps = ['/','-','\\']
    model_nodes.each_with_index do |model, index|
      print spinner_steps[index % spinner_steps.length]

      # Convert column definitions to serializable format
      columns = model['data']['columns'].inspect

      # Update columns property
      node = Neography::Node.load model['self'].split('/').last
      Neo4jRestIllustrator.connection.neo_server.set_node_properties node, {'columns' => columns}
      print '\b'
    end
  end
end
