################################################################################
#                                                                              #
#                  EP3: Interpolacao e diferenciacao numerica                  #
#                                                                              #
#                       Pedro Pereira     - NUSP 9778794                       #
#                       Raphael R. Gusmao - NUSP 9778561                       #
#                                                                              #
################################################################################
1;

################################################################################
# Interpolacao de imagem
function interpolaImagem(fileName = false, scale = 5)
    # Entrada dos valores caso o arquivo nao foi especificado
    if (fileName == false)
        try
            fileName = input("Digite o nome da imagem: ");
        catch
            if (strfind(lasterror.message, "undefined"))
                disp("O nome do arquivo deve ser entre aspas!");
                disp("Por favor rode a funcao novamente.");
            endif
        end_try_catch
    endif

    # Imagem original
    try
      img = imread(fileName);
    catch
      if (strfind(lasterror.message, "imread"))
         disp("Erro lendo a imagem!");
         disp("Tenha certeza que voce inseriu o nome certo.");
      else
         disp("Um erro inesperado aconteceu: ");
         disp(lasterror.message);
      endif
      return
    end_try_catch
    imgX = size(img,2); imgY = size(img,1);

    # Comprime a imagem original
    comp = compress(img, scale);
    compX = size(comp,2); compY = size(comp,1);

    # Descomprime a imagem comprimida
    dec = decompress(comp, scale);
    decX = size(dec,2); decY = size(dec,1);

    # Plota a imagem original, a comprimida e a descomprimida
    clf;
    subplot(1,3,1);
     imshow(img);
     title(strcat("[",num2str(imgX),"x",num2str(imgX),"] Imagem original"));
    subplot(1,3,2);
     imshow(comp);
     title(strcat("[",num2str(compX),"x",num2str(compY),"] Imagem comprimida"));
    subplot(1,3,3);
     imshow(dec);
     title(strcat("[",num2str(decX),"x",num2str(decY),"] Imagem descomprimida"));
end

################################################################################
# Interpolacao de funcao
# Recebe input do usuario ou uma funcao anonima (do estilo f = @(x, y))
# Imprime os valores da funcao comprimidos e uma aproximacao para os valores reais.
function interpolaFuncao(drawDiff = false,
                         f = false,
                         scale = 10,
                         ax = 0, bx = 9,
                         ay = 0, by = 9,
                         hx = 1, hy = 1)
    # Entrada dos valores
    try
      if (f == false)
          disp("Escolha uma das funcoes abaixo");
          disp(" 1: f(x,y) = xy");
          disp(" 2: f(x,y) = x + y");
          disp(" 3: f(x,y) = x^2 - 2y + 2");
          disp(" 4: f(x,y) = sen(x^2) + 3cos(y)");
          nFun = input(" > ");
          # Escolha da funcao
          if (nFun == 1) # f(x,y) = xy
              f = @(x, y) x.*y;
          elseif (nFun == 2) # f(x,y) = x + y
              f = @(x, y) x + y;
          elseif (nFun == 3) # f(x,y) = x^2 - 2y + 2
              f = @(x, y) x.^2 - 2*y + 2;
          else # f(x,y) = sen(x^2) + 3cos(y)
              f = @(x, y) sin(x.^2) + 3*cos(y);
          endif
      endif   
    end_try_catch

    # Quantidade de pontos na malha
    nx = (1+(bx-ax)/hx); ny = (1+(by-ay)/hy);

    # n^2 pontos da 'malha grossa' distribuidos uniformemente entre a e b
    X = linspace(ax, bx, nx);
    Y = linspace(ay, by, ny);

    # Matriz com os pontos f(x,y)
    [X_, Y_] = meshgrid(X, Y);
    F = f(X_, Y_);

    # pontos distribuidos entre a e b, malha fina, para ver como a funcao
    # realmente se comporta
    Xfin = linspace(ax, bx, nx * scale);
    Yfin = linspace(ay, by, ny * scale);
    [X_fin, Y_fin] = meshgrid(Xfin, Yfin);
    Ffin = f(X_fin, Y_fin);

    # Matriz dos coeficientes
    coef = constroiv(ax, bx, ay, by, hx, hy, nx, ny, F);

    # Inicializa a matriz das aproximacoes v(x,y)
    V = zeros(ny*scale, nx*scale);

    # n*scale pontos da 'malha fina' distribuidos uniformemente entre a e b
    Xs = linspace(ax, bx, nx*scale);
    Ys = linspace(ay, by, ny*scale);

    # Percorre a 'malha fina' e avalia v em todos os pontos (x,y)
    for i = 1:nx*scale
        for j = 1:ny*scale
            V(j,i) = avaliav(Xs(i), Ys(j), ax, bx, ay, by, hx, hy, nx, ny, coef);
        endfor
    endfor

    # Plota f e v
    clf;
    if(drawDiff)
      # Plota com diferenca |f - v|
      # DIFF = diferenca entre as malhas grossas (pontos de interpolacao)
      # DIFFfin = diferenca entre as malhas finas (Todos os pontos)
      DIFF = zeros(ny, nx);
      DIFFfin = zeros(ny*scale, nx*scale);
      for i = 1:nx
        for j = 1:ny
          # Avalia a diferenca nos pontos de interpolacao: esta deve ser zero
          DIFF(j, i) = abs(avaliav(X(i), Y(j), ax,bx,ay,by,hx,hy,nx,ny,coef) - f(X(i), Y(j)));
        endfor
      endfor
      # Mostra a diferenca no console: Melhor que gastar espaco do plot
      # Alem do mais, erros de rounding seriam ampliados no grafico
      disp("A diferenca de |f - v| nos pontos de interpolacao:");
      DIFF
      for i = 1:nx*scale
        for j = 1:ny*scale
          # Avalia a diferenca em todos os pontos
          DIFFfin(j, i) = abs(V(j, i) - Ffin(j, i));
        endfor
      endfor
      printf("A media do erro da interpolacao foi: ");
      mean(mean(DIFFfin))
      subplot(2, 2, 1);
       draw(strcat("f(x, y) - (",num2str(nx*scale),"x",num2str(ny*scale),") pontos"), Xfin, Yfin, Ffin);
      subplot(2, 2, 2);
       draw(strcat("f(x,y) - (",num2str(nx),"x",num2str(ny),") pontos"), X, Y, F);
      subplot(2, 2, 3);
       draw(strcat("v(x,y) - (",num2str(nx*scale),"x",num2str(ny*scale),") pontos"), Xs, Ys, V);
      subplot(2, 2, 4);
       draw(strcat("|f - v| em todos os (",num2str(nx*scale),"x",num2str(ny*scale),") pontos"), Xs, Ys, DIFFfin);      
    else
      # Plota sem diferenca |f - v|  
      subplot(1, 3, 1);
       draw(strcat("f(x, y) - (",num2str(nx*scale),"x",num2str(ny*scale),") pontos"), Xfin, Yfin, Ffin);
      subplot(1, 3, 2);
       draw(strcat("f(x,y) - (",num2str(nx),"x",num2str(ny),") pontos"), X, Y, F);
      subplot(1, 3, 3);
       draw(strcat("v(x,y) - (",num2str(nx*scale),"x",num2str(ny*scale),") pontos"), Xs, Ys, V);
    endif
end

################################################################################
# Handler para a interpolaFuncao
# Carrega um arquivo na memoria, e aplica a interpolacao.
# O formato do arquivo deve ser exatamente o que o comando "save" gera.
# exemplo: definidos ax, ay, bx, by, hx, hy, scale e a f no ambiente, eh possivel
# aplicar o seguinte comando:
# > save "arquivo.txt" f ax ay bx by hx hy
# (na ordem que quiser, desde que os nomes das variaveis sejam os mesmos)
# e, apos isso, rodar este handler.
function interpolaHandler(fileName)
    try
        load fileName;
        interpolaFuncao(f, ax, bx, ay, by, hx, hy, scale);
    catch
        if (strfind(lasterror.message, "load:"))
            disp("Erro em load: voce colocou todas as variaveis no arquivo?");
            disp(lasterror.message);
        else
            printf("Um erro inesperado aconteceu: ");
            disp(lasterror.message);
        endif
    end_try_catch
end

################################################################################
# Comprime uma imagem
function [comp] = compress(img, scale)
    # Quantidade de pixels da imagem comprimida
    nx = max(1, size(img, 2)/scale); ny = max(1, size(img, 1)/scale);

    # Matrizes com as componentes RGB da imagem
    R = double(img(:,:,1));
    G = double(img(:,:,2));
    B = double(img(:,:,3));

    # Inicializa a matriz da imagem comprimida
    comp = zeros(ny, nx, 3);

    # Seleciona apenas uma 'malha grossa' da imagem original
    for i = 1:ny
        for j = 1:nx
            comp(i,j,:) = [R(i*scale,j*scale);
                           G(i*scale,j*scale);
                           B(i*scale,j*scale)];
        endfor
    endfor

    # Converte a matriz com para o formato correto para imagem
    comp = uint8(comp);
end

################################################################################
# Descomprime uma imagem
function [dec] = decompress(img, scale)
    # Quantidade de pixels da imagem comprimida
    nx = size(img, 2); ny = size(img, 1);

    # Dimensoes da imagem
    ax = 1; bx = nx; ay = 1; by = ny;
    hx = 1; hy = 1;

    # Matrizes com as componentes RGB da imagem
    R = double(img(:,:,1));
    G = double(img(:,:,2));
    B = double(img(:,:,3));

    # Matriz dos coeficientes das componentes RGB
    coefR = constroiv(ax, bx, ay, by, hx, hy, nx, ny, R);
    coefG = constroiv(ax, bx, ay, by, hx, hy, nx, ny, G);
    coefB = constroiv(ax, bx, ay, by, hx, hy, nx, ny, B);

    # Inicializa as matrize das aproximacoes v para as componentes RGB
    vR = zeros(nx*scale, ny*scale);
    vG = zeros(nx*scale, ny*scale);
    vB = zeros(nx*scale, ny*scale);

    # Inicializa a matriz da imagem descomprimida
    dec = zeros(ny*scale, nx*scale, 3);

    # n*scale pontos da malha fina distribuidos uniformemente entre a e b
    X = linspace(ax, bx, nx*scale);
    Y = linspace(ay, by, ny*scale);

    # Percorre a malha e avalia v em todos os pontos (x,y)
    for i = 1:nx*scale
        for j = 1:ny*scale
            vR(i,j) = avaliav(X(i), Y(j), ax, bx, ay, by, hx, hy, nx, ny, coefR);
            vG(i,j) = avaliav(X(i), Y(j), ax, bx, ay, by, hx, hy, nx, ny, coefG);
            vB(i,j) = avaliav(X(i), Y(j), ax, bx, ay, by, hx, hy, nx, ny, coefB);
            dec(j,i,:) = [vR(i,j); vG(i,j); vB(i,j)];
        endfor
    endfor

    # Converte a matriz dec para o formato correto para imagem
    dec = ceil(uint8(dec));
end

################################################################################
# Avalia v em um ponto (x,y)
function ret = avaliav(x, y, ax, bx, ay, by, hx, hy, nx, ny, coef)
    # n pontos da 'malha grossa' distribuidos uniformemente entre a e b
    X = linspace(ax, bx, nx);
    Y = linspace(ay, by, ny);

    # Encontra o ponto superior esquerdo mais proximo de (x,y)
    i = 1;
    while (i+1 < nx && X(i+1) < x)
        i = i + 1;
    endwhile
    j = 1;
    while (j+1 < ny && Y(j+1) < y)
        j = j + 1;
    endwhile

    # Calcula v(x,y) = uma aproximacao de f(x,y)
    m1 = [1, (x - X(i))/hx, ((x - X(i))/hx)^2, ((x - X(i))/hx)^3];
    m2 = [1; (y - Y(j))/hy; ((y - Y(j))/hy)^2; ((y - Y(j))/hy)^3];
    ret = m1 * coef(:,:, i, j) * m2;
end

################################################################################
# Constroi a matriz dos coeficientes para calcular v(x,y)
function coef = constroiv(ax, bx, ay, by, hx, hy, nx, ny, F)
    # Matrizes das aproximacao das derivadas de f
    [dxF, dyF, dxyF] = aproxdf(ax, bx, ay, by, hx, hy, nx, ny, F);
    F = transpose(F);
    dxF = transpose(dxF);
    dyF = transpose(dyF);
    dxyF = transpose(dxyF);

    # Inicializa a matriz dos coeficientes
    coef = zeros(4, 4, (nx-1),(ny-1));

    # Calcula a matriz dos coeficientes
    for i = 1:nx-1
        for j = 1:ny-1
            m1 = [1, 0,    0,    0;
                  1, 1,    1,    1;
                  0, 1/hx, 0,    0;
                  0, 1/hx, 2/hx, 3/hx];
            fMat = [  F(i,   j),   F(i,   j+1),  dyF(i,   j),  dyF(i,   j+1);
                      F(i+1, j),   F(i+1, j+1),  dyF(i+1, j),  dyF(i+1, j+1);
                    dxF(i,   j), dxF(i,   j+1), dxyF(i,   j), dxyF(i,   j+1);
                    dxF(i+1, j), dxF(i+1, j+1), dxyF(i+1, j), dxyF(i+1, j+1)];
            m2 = [1, 1, 0,    0;
                  0, 1, 1/hy, 1/hy;
                  0, 1, 0,    2/hy;
                  0, 1, 0,    3/hy];
            coef(:,:, i, j) = inv(m1) * fMat * inv(m2);
        endfor
    endfor
end

################################################################################
# Encontra aproximacoes O(h^2) para dxf, dyf e dxyf em todos os pontos da malha
function [dxF, dyF, dxyF] = aproxdf(ax, bx, ay, by, hx, hy, nx, ny, F)
    # Utiliza a transposta de F (para facilitar o codigo)
    F = transpose(F);

    # Inicializa as matrizes das derivadas
    dxF = zeros(nx, ny);
    dyF = zeros(nx, ny);
    dxyF = zeros(nx, ny);

    # Percorre a matriz F e encontra as derivadas nos pontos
    for i = 1:nx-1
        for j = 1:ny-1
            dxF(i,j) = (F(i+1, j) - F(i, j))/hx;
            dyF(i,j) = (F(i, j+1) - F(i, j))/hy;
            dxyF(i,j) = (F(i+1, j+1) - F(i+1, j) - F(i, j+1) + F(i, j))/(hx*hy);
        endfor
    endfor

    # Percorre a extremidade direita da matriz F
    i = nx;
    for j = 2:ny-1
        dxF(i,j) = (F(i, j) - F(i-1, j))/hx;
        dyF(i,j) = (F(i, j) - F(i, j-1))/hy;
        dxyF(i,j) = (F(i, j) - F(i, j-1) - F(i-1, j) + F(i-1, j-1))/(hx*hy);
    endfor
    
    # Percorre a extremidade inferior da matriz F
    j = ny;
    for i = 2:nx-1
        dxF(i,j) = (F(i, j) - F(i-1, j))/hx;
        dyF(i,j) = (F(i, j) - F(i, j-1))/hy;
        dxyF(i,j) = (F(i, j) - F(i, j-1) - F(i-1, j) + F(i-1, j-1))/(hx*hy);
    endfor

    # Ponto da extremidade superior direita
    i = nx; j = 1;
    dxF(i,j) = (F(i, j) - F(i-1, j))/hx;
    dyF(i,j) = (F(i, j+1) - F(i, j))/hy;
    dxyF(i,j) = (F(i, j+1) - F(i, j) - F(i-1, j+1) + F(i-1, j))/(hx*hy);

    # Ponto da extremidade inferior esquerda
    i = 1; j = ny;
    dxF(i,j) = (F(i+1, j) - F(i, j))/hx;
    dyF(i,j) = (F(i, j) - F(i, j-1))/hy;
    dxyF(i,j) = (F(i+1, j) - F(i+1, j-1) - F(i, j) + F(i, j-1))/(hx*hy);

    # Ponto da extremidade inferior direita
    i = nx; j = ny;
    dxF(i,j) = (F(i, j) - F(i-1, j))/hx;
    dyF(i,j) = (F(i, j) - F(i, j-1))/hy;
    dxyF(i,j) = (F(i, j) - F(i, j-1) - F(i-1, j) + F(i-1, j-1))/(hx*hy);

    # Calcula as transpostas das derivadas (para facilitar o codigo)
    dxF = transpose(dxF);
    dyF = transpose(dyF);
    dxyF = transpose(dxyF);
end

################################################################################
# Plota a matriz F em escala de cinza (valores maiores <=> cores mais claras)
function draw(titulo, x, y, F)
    nMin = min(min(F));
    nMax = max(max(F));
    #colorMat = ceil(255 .* (F .- nMin)./(nMax + abs(nMin)));
    colorMat = zeros(length(y), length(x));
    for i = 1:length(y)
        for j = 1:length(x)
            if (nMax != nMin)
                colorMat(i, j) = ceil(255*(F(i, j) - nMin)/(nMax + abs(nMin)));
            else
                colorMat(i, j) = 0;
            endif
        endfor
    endfor
    c = transpose(linspace(0, 1, 256));
    colormap([c,c,c]);
    imagesc(x, y, colorMat);
    title(titulo); xlabel("x"); ylabel("y");
end

################################################################################
# Funcao de demonstracao do programa
function demo()
    disp("Vendo a interpolacao de mario.png...");
    interpolaImagem("mario.png", 2);
    _ = input("Digite enter para visualizar a proxima funcao: ");
    disp("Vendo a interpolacao de sgt100.jpg...");
    interpolaImagem("sgt.jpg", 2);
    _ = input("Digite enter para visualizar a proxima funcao: ");
    disp("Vendo a aproximacao da funcao f(x, y) = xy..."); 
    interpolaFuncao(true, @(x, y) x.*y, 4);
    _ = input("Digite enter para visualizar a proxima funcao: ");
    disp("Vendo a aproximacao da funcao f(x, y) = x + y...");
    interpolaFuncao(true, @(x, y) x + y);
    _ = input("Digite enter para visualizar a proxima funcao: ");
    disp("Vendo a aproximacao da funcao f(x, y) = x^2 - 2y + 2...");
    interpolaFuncao(true, @(x, y) x .^ 2 - 2 * y + 2);
    _ = input("Digite enter para visualizar a proxima funcao: ");
    disp("Vendo a aproximacao da funcao f(x, y) = sen(x^2) + 3cos(y)...");
    interpolaFuncao(true, @(x, y) sin(x.^2) + 3 * cos(y));
end