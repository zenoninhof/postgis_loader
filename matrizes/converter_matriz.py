import pandas as pd
from pathlib import Path


def csv_to_fma(input_csv, output_fma, delimiter=","):
    """
    Converte CSV (origem, destino, valor) para .fma (VISUM).

    Espera colunas:
    [origem, destino, valor]
    """

    input_csv = Path(input_csv)
    output_fma = Path(output_fma)

    # Ler CSV
    df = pd.read_csv(input_csv, delimiter=delimiter)

    # Validação básica
    if df.shape[1] < 3:
        raise ValueError("CSV precisa ter pelo menos 3 colunas: origem, destino, valor")

    # Forçar tipos corretos
    df.iloc[:, 0] = df.iloc[:, 0].astype(int)
    df.iloc[:, 1] = df.iloc[:, 1].astype(int)
    df.iloc[:, 2] = df.iloc[:, 2].astype(float)

    # Escrita eficiente (sem iterrows)
    with open(output_fma, "w") as f:
        f.write("$O;D3\n")
        f.write("* From To Value\n")

        linhas = (
            f"{o} {d} {v}"
            for o, d, v in zip(df.iloc[:, 0], df.iloc[:, 1], df.iloc[:, 2])
        )

        f.write("\n".join(linhas))

    print(f"Arquivo .fma gerado: {output_fma}")


if __name__ == "__main__":
    csv_to_fma("C:\\Users\\zeno.filho\\Downloads\\vw_mtx_pessoas_auto_seed_202604101030.csv", "C:\\Users\\zeno.filho\\Downloads\\matriz2023calib.fma")