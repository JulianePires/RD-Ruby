require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, customer_success_away)
    @customer_success = customer_success
    @customers = customers
    @customer_success_away = customer_success_away
  end

  # Returns the id of the CustomerSuccess with the most customers
  def execute
    matches = {} #um hash para armazenar os matches entre os customers e css
    prevScore = 0 #uma variável auxiliar para o controle do score

    #deleta os css que estão fora
    custSuc = @customer_success.reject { |css| @customer_success_away.include?(css[:id]) }
    #ordena os css por score
    custSuc.sort_by! { |css| css[:score] }
    #ordena os customers pelo score
    customers = @customers.sort_by { |cust| cust[:score] }
    #itera pelos css
    custSuc.each do |css|
      #armazena os customers que os css pode atender (<= ao seu score)
      can_match = customers.select do |customer| 
        customer[:score] <= css[:score] and customer[:score] > prevScore
      end
      #armazena o score atual na variável auxiliar
      prevScore = css[:score]
      #score = quantidade de customers que podem ser atendidos
      score = can_match.length
      #se o hash de maps não conter conter a quantidade
      if !matches.has_key?(score) then
        #cria uma chave com a quantidade
        matches[score] = []
      end
      #o hash matches na posição da quantidade de customers recebe o id do css
      matches[score].push(css[:id])
    end
    #o valor máximo será o máximo do array de keys (quantidades de customers)
    max = matches.keys.max
    #operador ternário -> se tiver mais de um max devolve 0, senão devolve o max
    matches[max].length > 1 ? 0 : matches[max][0]
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    css = [{ id: 1, score: 60 }, { id: 2, score: 20 }, { id: 3, score: 95 }, { id: 4, score: 75 }]
    customers = [{ id: 1, score: 90 }, { id: 2, score: 20 }, { id: 3, score: 70 }, { id: 4, score: 40 }, { id: 5, score: 60 }, { id: 6, score: 10}]

    balancer = CustomerSuccessBalancing.new(css, customers, [2, 4])
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    css = array_to_map([11, 21, 31, 3, 4, 5])
    customers = array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60])
    balancer = CustomerSuccessBalancing.new(css, customers, [])
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    customer_success = Array.new(1000, 0)
    customer_success[998] = 100

    customers = Array.new(10000, 10)
    
    balancer = CustomerSuccessBalancing.new(array_to_map(customer_success), array_to_map(customers), [1000])

    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 999, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(array_to_map([1, 2, 3, 4, 5, 6]), array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [])
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(array_to_map([100, 2, 3, 3, 4, 5]), array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [])
    assert_equal balancer.execute, 1
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(array_to_map([100, 99, 88, 3, 4, 5]), array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [1, 3, 2])
    assert_equal balancer.execute, 0
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(array_to_map([100, 99, 88, 3, 4, 5]), array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [4, 5, 6])
    assert_equal balancer.execute, 3
  end

  def array_to_map(arr)
    out = []
    arr.each_with_index { |score, index| out.push({ id: index + 1, score: score }) }
    out
  end
end

Minitest.run